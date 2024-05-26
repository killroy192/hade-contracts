// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {HadeToken} from "src/HadeToken.sol";
import {LinkedList, LinkedListLibrary} from "src/LinkedList.sol";
import {IStrikeOracle, StrikeTypes} from "src/strikeOracle/StrikeOracle.types.sol";

error WrongMarketPeriod(uint32 period);
error MarketAlreadyCreated();
error MarketIsNotExist();
error RollingTooEarly();
error RedeemPeriod();
error MintPeriod();
error InvalidToken();

struct MarketConfig {
    address token0;
    address token1;
    address oracle;
    uint32 period;
}

struct MarketState {
    uint256 strike;
    uint256 lastRoll;
}

struct Market {
    MarketConfig config;
    MarketState state;
    HadeToken token;
}

contract MarketManager is ReentrancyGuard {
    using LinkedListLibrary for LinkedList;
    using Math for uint256;

    uint32 public constant REDEEM_PERIOD = 7200; // ~ 1 day
    uint32 public constant WEEK_PERIOD = 50400;
    uint32 public constant MONTH_PERIOD = 216000;
    uint32 public constant HALF_YEAR = 1296000;
    uint32 public constant YEAR = 2628000;

    mapping(bytes32 => Market) public markets;
    mapping(bytes32 => LinkedList) public marketQs;
    mapping(bytes32 => mapping(address => uint256)) public marketLedgers;

    modifier validPeriod(uint32 period) {
        if (
            period != WEEK_PERIOD || period != MONTH_PERIOD || period != HALF_YEAR || period != YEAR
        ) {
            revert WrongMarketPeriod(period);
        }
        _;
    }

    modifier marketNotExist(Market memory market) {
        if (market.config.period != 0) {
            revert MarketAlreadyCreated();
        }
        _;
    }

    modifier marketExist(Market memory market) {
        if (market.config.period == 0) {
            revert MarketIsNotExist();
        }
        _;
    }

    modifier canMint(Market memory market) {
        if (market.state.lastRoll + market.config.period - REDEEM_PERIOD > block.number) {
            revert RedeemPeriod();
        }
        _;
    }

    modifier canRedeem(Market memory market) {
        if (
            market.state.lastRoll + market.config.period - REDEEM_PERIOD >= block.number
                && block.number <= market.state.lastRoll + market.config.period
        ) {
            revert MintPeriod();
        }
        _;
    }

    modifier validToken(Market memory market, address token) {
        if (market.config.token0 != token || market.config.token1 != token) {
            revert InvalidToken();
        }
        _;
    }

    function periodName(uint32 period) private pure returns (string memory) {
        if (period == WEEK_PERIOD) {
            return "_weekly";
        }
        if (period == MONTH_PERIOD) {
            return "_monthly";
        }
        if (period == HALF_YEAR) {
            return "_half_year";
        }
        return "_yearly";
    }

    function typeName(StrikeTypes strikeType) private pure returns (string memory) {
        if (strikeType == StrikeTypes.Classic) {
            return "_classic";
        }
        return "_up";
    }

    function marketId(MarketConfig calldata marketConfig) public pure returns (bytes32) {
        return keccak256(abi.encode(marketConfig));
    }

    function create(MarketConfig calldata marketConfig) external {
        _create(marketId(marketConfig), marketConfig);
    }

    function _create(bytes32 id, MarketConfig calldata marketConfig)
        private
        marketNotExist(markets[id])
        validPeriod(marketConfig.period)
    {
        markets[id].config = marketConfig;
        string memory tokenName = string(
            abi.encodePacked(
                "hd",
                ERC20(marketConfig.token0).symbol(),
                "_",
                ERC20(marketConfig.token1).symbol(),
                periodName(marketConfig.period),
                typeName(IStrikeOracle(marketConfig.oracle).getStrikeType())
            )
        );
        markets[id].token = new HadeToken(
            tokenName,
            tokenName
        );
    }

    function roll(bytes32 id) external marketExist(markets[id]) {
        Market storage market = markets[id];
        MarketState memory state = market.state;
        MarketConfig memory config = market.config;
        if (state.lastRoll + config.period < block.number) {
            revert RollingTooEarly();
        }
        market.state = MarketState({
            strike: IStrikeOracle(config.oracle).getStrike(state.strike),
            lastRoll: state.lastRoll + config.period
        });
    }

    function mint(bytes32 id, uint256 amount) external nonReentrant {
        _mint(markets[id], amount);
        marketQs[id].reorg(msg.sender);
        marketLedgers[id][msg.sender] = amount;
    }

    function _mint(Market memory market, uint256 amount)
        private
        marketExist(market)
        canMint(market)
    {
        MarketState memory state = market.state;
        MarketConfig memory config = market.config;

        ERC20(config.token0).transferFrom(msg.sender, address(this), amount);
        ERC20(config.token1).transferFrom(msg.sender, address(this), amount * state.strike);

        market.token.mintTo(msg.sender, amount);
        // rebalance according to new ratio - out of PoC
    }

    function redeem(bytes32 id, uint256 token0Amount, address token) external nonReentrant {
        _redeem(markets[id], id, token0Amount, token);
    }

    function _redeem(Market memory market, bytes32 id, uint256 token0Amount, address token)
        private
        marketExist(market)
        canRedeem(market)
        validToken(market, token)
    {
        MarketState memory state = market.state;
        MarketConfig memory config = market.config;

        market.token.burnFrom(msg.sender, token0Amount);

        uint256 change = token0Amount;
        while (change > 0) {
            address owner = marketQs[id].head;
            uint256 balance = marketLedgers[id][owner];

            uint256 toWithdraw = balance >= change ? change : balance;

            if (token == config.token0) {
                ERC20(config.token0).transferFrom(address(this), msg.sender, toWithdraw);
                ERC20(config.token1).transferFrom(address(this), owner, toWithdraw * state.strike);
            } else {
                ERC20(config.token0).transferFrom(address(this), owner, toWithdraw);
                ERC20(config.token1).transferFrom(
                    address(this), msg.sender, toWithdraw * state.strike
                );
            }

            if (toWithdraw < balance) {
                marketLedgers[id][owner] = balance - toWithdraw;
            } else {
                marketLedgers[id][owner] = 0;
                marketQs[id].shift();
            }
            change -= toWithdraw;
        }
    }

    // OUT of PoC scope
    function cancelRolling(bytes32 id) external canRedeem(markets[id]) {
        // create new additional q for forced redemptions
    }

    function forceRedeem(bytes32 id) external {
        // forcely redeem if was registerd in force redemtion q
    }
}
