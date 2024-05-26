// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {HadeToken} from "src/HadeToken.sol";
import {LinkedList, LinkedListLibrary} from "src/LinkedList.sol";
import {IStrikeOracle, StrikeTypes} from "src/strikeOracle/StrikeOracle.types.sol";
import {PeriodsLib} from "src/PeriodsLib.sol";
import {TokenMath} from "src/TokenMath.sol";

error UnsupportedPeriod(uint32 period);
error MarketAlreadyCreated();
error MarketIsNotExist();
error RollingTooEarly();
error RedeemSession();
error MintSession();
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

/**
 * @dev PoC supports only 16dec ERC
 */
contract MarketManager is ReentrancyGuard {
    using LinkedListLibrary for LinkedList;
    using Math for uint256;
    using TokenMath for uint256;

    mapping(bytes32 => Market) private markets;
    mapping(bytes32 => LinkedList) private marketQs;
    mapping(bytes32 => mapping(address => uint256)) private marketLedgers;

    modifier validPeriod(uint32 period) {
        if (!PeriodsLib.isPeriodValid(period)) {
            revert UnsupportedPeriod(period);
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
        uint256 endMintBlock =
            market.state.lastRoll + market.config.period - PeriodsLib.REDEEM_PERIOD;
        if (block.number >= endMintBlock) {
            revert RedeemSession();
        }
        _;
    }

    modifier canRedeem(Market memory market) {
        if (
            market.state.lastRoll + market.config.period - PeriodsLib.REDEEM_PERIOD >= block.number
                && block.number <= market.state.lastRoll + market.config.period
        ) {
            revert MintSession();
        }
        _;
    }

    modifier validToken(Market memory market, address token) {
        if (market.config.token0 != token || market.config.token1 != token) {
            revert InvalidToken();
        }
        _;
    }

    function typeName(StrikeTypes strikeType) private pure returns (string memory) {
        if (strikeType == StrikeTypes.Classic) {
            return "_classic";
        }
        return "_up";
    }

    function marketId(MarketConfig calldata config) public pure returns (bytes32) {
        return keccak256(abi.encode(config));
    }

    function getMarket(bytes32 id) external view returns (Market memory) {
        return markets[id];
    }

    function create(MarketConfig calldata config) external returns (bytes32 id) {
        id = marketId(config);
        Market storage market = markets[id];
        _create(market, config);
    }

    function _create(Market storage market, MarketConfig calldata config)
        private
        marketNotExist(market)
        validPeriod(config.period)
    {
        market.config = config;
        string memory tokenName = string(
            abi.encodePacked(
                "hd",
                ERC20(config.token0).symbol(),
                "_",
                ERC20(config.token1).symbol(),
                "_",
                PeriodsLib.periodName(config.period),
                typeName(IStrikeOracle(config.oracle).getStrikeType())
            )
        );
        market.token = new HadeToken(
            tokenName,
            tokenName
        );
        market.state =
            MarketState({strike: IStrikeOracle(config.oracle).getStrike(), lastRoll: block.number});
    }

    function mint(bytes32 id, uint256 token0Amount) external nonReentrant {
        _mint(markets[id], token0Amount);
        marketQs[id].reorg(msg.sender);
        marketLedgers[id][msg.sender] += token0Amount;
    }

    function _mint(Market memory market, uint256 token0Amount)
        private
        marketExist(market)
        canMint(market)
    {
        MarketState memory state = market.state;
        MarketConfig memory config = market.config;

        ERC20(config.token0).transferFrom(msg.sender, address(this), token0Amount);
        ERC20(config.token1).transferFrom(
            msg.sender, address(this), token0Amount.convert(state.strike, config.oracle)
        );

        market.token.mintTo(msg.sender, token0Amount);
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
                ERC20(config.token1).transferFrom(
                    address(this), owner, toWithdraw.convert(state.strike, config.oracle)
                );
            } else {
                ERC20(config.token0).transferFrom(address(this), owner, toWithdraw);
                ERC20(config.token1).transferFrom(
                    address(this), msg.sender, toWithdraw.convert(state.strike, config.oracle)
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

    /**
     * @dev MVP oos
     */

    function roll(bytes32 id) external marketExist(markets[id]) {
        Market storage market = markets[id];
        MarketConfig memory config = market.config;
        MarketState memory state = market.state;
        if (state.lastRoll + config.period > block.number) {
            revert RollingTooEarly();
        }
        market.state = MarketState({
            strike: IStrikeOracle(config.oracle).getStrike(state.strike),
            lastRoll: state.lastRoll + config.period
        });
    }

    function cancelRolling(bytes32 id) external canRedeem(markets[id]) {
        // create new additional q for forced redemptions
    }

    function forceRedeem(bytes32 id) external {
        // forcely redeem if was registerd in force redemtion q
    }
}
