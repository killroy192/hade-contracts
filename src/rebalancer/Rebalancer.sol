// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {HadeToken} from "src/HadeToken.sol";
import {IRebalancerRegistry} from "src/RebalancerRegistry.types.sol";

error DepositAndWithdrawForbidden();
error SwapForbidden();

interface IOracle {
    function getHedgePrice() external view returns (uint256);
    function getExposurePrice() external view returns (uint256);
}

struct SwapProps {
    address tokenToSell;
    uint256 maxAmountToSell;
    uint256 sellPrice;
    address tokenToBuy;
    uint256 buyPrice;
}

struct OperationProps {
    bool canDepositOrWithdraw;
    address opToken;
}

struct Config {
    address exposureToken;
    address hedgeToken;
    address oracle;
    address registry;
    uint256 multiplier;
    uint256 rebalanceHedgePrice;
}

struct State {
    ERC20 exposureToken;
    ERC20 hedgeToken;
    HadeToken sharesToken;
    IOracle oracle;
    uint256 multiplier;
    uint256 rebalanceHedgePrice;
}

struct SerializedState {
    address exposureToken;
    address hedgeToken;
    address sharesToken;
    address oracle;
    uint256 multiplier;
    uint256 rebalanceHedgePrice;
}

library RebalancerTypeLib {
    enum RTypes {
        Tick,
        PeriodTick,
        UpOnlyTick
    }

    function typeName(RTypes rebType) external pure returns (string memory) {
        if (rebType == RTypes.Tick) {
            return "tick";
        }
        if (rebType == RTypes.PeriodTick) {
            return "periodTick";
        }
        return "upOnlyTick";
    }
}

contract Rebalancer is ReentrancyGuard {
    using Math for uint256;
    using RebalancerTypeLib for RebalancerTypeLib.RTypes;

    State private s;

    RebalancerTypeLib.RTypes private constant rebType = RebalancerTypeLib.RTypes.Tick;

    // discount same decimals
    constructor(Config memory _config) {
        ERC20 exposureToken = ERC20(_config.exposureToken);
        ERC20 hedgeToken = ERC20(_config.hedgeToken);
        string memory tokenName = string(
            abi.encodePacked(
                "hd", exposureToken.symbol(), "_", hedgeToken.symbol(), "_", rebType.typeName()
            )
        );
        HadeToken sharesToken = new HadeToken(
                tokenName,
                tokenName
            );

        s = State({
            exposureToken: ERC20(_config.exposureToken),
            hedgeToken: ERC20(_config.hedgeToken),
            sharesToken: sharesToken,
            oracle: IOracle(_config.oracle),
            multiplier: _config.multiplier,
            rebalanceHedgePrice: _config.rebalanceHedgePrice
        });

        IRebalancerRegistry(_config.registry).register(address(this));
    }

    function decimals() private pure returns (uint8) {
        return 8;
    }

    function previewSwap() public view returns (SwapProps memory) {
        // h = usd
        // e = eth
        // hPrice = 0.1 e
        // ePrice = 10 h

        uint256 hPrice = s.oracle.getHedgePrice();
        uint256 ePrice = s.oracle.getExposurePrice();

        // rebalanceHedgePrice = 0.05 e
        // hedgeEnabled = true
        bool hedgeEnabled = hPrice < s.rebalanceHedgePrice;

        // sell exposureToken
        ERC20 tokenToSell = hedgeEnabled ? s.exposureToken : s.hedgeToken;
        // buy hedgeToken
        ERC20 tokenToBuy = hedgeEnabled ? s.hedgeToken : s.exposureToken;

        // sell exposureToken -> ePrice / 1.1 -> 9.(09)
        uint256 sellPrice = (hedgeEnabled ? ePrice : hPrice).mulDiv(decimals(), s.multiplier);
        // buy hedgeToken -> hPrice * 1.1 -> 0.11
        uint256 buyPrice = (hedgeEnabled ? hPrice : ePrice).mulDiv(s.multiplier, decimals());

        // how many exposureToken can sell for hedgeToken
        uint256 maxAmountToSell = tokenToSell.balanceOf(address(this)) * sellPrice;

        return SwapProps({
            tokenToSell: address(tokenToSell),
            maxAmountToSell: maxAmountToSell,
            sellPrice: sellPrice,
            tokenToBuy: address(tokenToBuy),
            buyPrice: buyPrice
        });
    }

    // amountToBuy -> amount to buy exposureToken
    function swap(uint256 amountToBuy) external nonReentrant {
        SwapProps memory sp = previewSwap();
        if (sp.maxAmountToSell == 0 || sp.maxAmountToSell < amountToBuy) {
            revert SwapForbidden();
        } else {
            ERC20 btoken = ERC20(sp.tokenToBuy);
            ERC20 stoken = ERC20(sp.tokenToSell);

            uint256 amountToCollect = amountToBuy * sp.sellPrice;
            btoken.transferFrom(msg.sender, address(this), amountToCollect);
            stoken.transfer(address(this), amountToBuy);
        }
    }

    function previewOperation() public view returns (OperationProps memory) {
        uint256 hPrice = s.oracle.getHedgePrice();

        bool hedgeEnabled = hPrice < s.rebalanceHedgePrice;

        address opToken = hedgeEnabled ? address(s.hedgeToken) : address(s.exposureToken);
        ERC20 rebalanceToken = hedgeEnabled ? s.exposureToken : s.hedgeToken;

        bool canDepositOrWithdraw = rebalanceToken.balanceOf(address(this)) == 0;
        return OperationProps({canDepositOrWithdraw: canDepositOrWithdraw, opToken: opToken});
    }

    function deposit(uint256 amount) external nonReentrant {
        OperationProps memory op = previewOperation();
        if (!op.canDepositOrWithdraw) {
            revert DepositAndWithdrawForbidden();
        } else {
            ERC20 token = ERC20(op.opToken);
            uint256 sharesToMint = amount.mulDiv(10 ** decimals(), token.balanceOf(address(this)));
            token.transferFrom(msg.sender, address(this), amount);
            s.sharesToken.mintTo(msg.sender, sharesToMint);
        }
    }

    function redeem(uint256 shares) external nonReentrant {
        OperationProps memory op = previewOperation();
        if (!op.canDepositOrWithdraw) {
            revert DepositAndWithdrawForbidden();
        } else {
            ERC20 token = ERC20(op.opToken);
            uint256 share = shares.mulDiv(10 ** decimals(), s.sharesToken.totalSupply());
            uint256 tokenToSend = share.mulDiv(token.balanceOf(address(this)), 10 ** decimals());
            s.sharesToken.burnFrom(msg.sender, shares);
            token.transfer(msg.sender, tokenToSend);
        }
    }

    /**
     * dev utils
     */

    function state() external view returns (SerializedState memory) {
        return SerializedState({
            exposureToken: address(s.exposureToken),
            hedgeToken: address(s.hedgeToken),
            sharesToken: address(s.sharesToken),
            oracle: address(s.oracle),
            multiplier: s.multiplier,
            rebalanceHedgePrice: s.rebalanceHedgePrice
        });
    }

    function isHedgeMode() external view returns (bool) {
        return s.oracle.getHedgePrice() < s.rebalanceHedgePrice;
    }
}
