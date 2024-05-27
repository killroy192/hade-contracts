// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {SharesToken} from "src/SharesToken.sol";
import {IOracle} from "src/oracle/Oracle.types.sol";
import {IRebalancerRegistry} from "src/registry/RebalancerRegistry.types.sol";

import {RTypeLib} from "./libs/RTypeLib.sol";
import {
    Config,
    SwapProps,
    SerializedState,
    RTypes,
    IRebalancer,
    DepositProps,
    RedeemProps,
    DepositForbidden,
    RedeemForbidden,
    SwapForbidden
} from "./Rebalancer.types.sol";

struct State {
    ERC20 exposureToken;
    ERC20 hedgeToken;
    SharesToken sharesToken;
    IOracle oracle;
    uint256 multiplier;
    uint256 rebalanceExposurePrice;
}

/**
 * todo add events
 */
contract Rebalancer is IRebalancer, ReentrancyGuard, ERC165 {
    using Math for uint256;
    using RTypeLib for RTypes;

    State private s;

    RTypes private constant rebType = RTypes.Tick;

    // discount same decimals
    constructor(Config memory _config) {
        ERC20 exposureToken = ERC20(_config.exposureToken);
        ERC20 hedgeToken = ERC20(_config.hedgeToken);
        string memory tokenName = string(
            abi.encodePacked(
                "hd", exposureToken.symbol(), "_", hedgeToken.symbol(), "_", rebType.toString()
            )
        );
        SharesToken _sharesToken = new SharesToken(
                tokenName,
                tokenName
            );

        s = State({
            exposureToken: ERC20(_config.exposureToken),
            hedgeToken: ERC20(_config.hedgeToken),
            sharesToken: _sharesToken,
            oracle: IOracle(_config.oracle),
            multiplier: _config.multiplier,
            rebalanceExposurePrice: _config.rebalanceExposurePrice
        });

        IRebalancerRegistry(_config.registry).register(address(this));
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IRebalancer).interfaceId || super.supportsInterface(interfaceId);
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function initSharesToMint() public pure returns (uint256) {
        return 100 * 10 ** decimals();
    }

    function _previewOperation() private view returns (bool canDepositOrWithdraw, address token) {
        uint256 ePrice = s.oracle.getExposurePrice(s.hedgeToken.decimals());

        bool hedgeEnabled = ePrice < s.rebalanceExposurePrice;

        token = hedgeEnabled ? address(s.hedgeToken) : address(s.exposureToken);
        ERC20 rebalanceToken = hedgeEnabled ? s.exposureToken : s.hedgeToken;

        canDepositOrWithdraw = rebalanceToken.balanceOf(address(this)) == 0;
    }

    function previewDeposit(uint256 amount) public view returns (DepositProps memory) {
        (bool canDepositOrWithdraw, address token) = _previewOperation();
        if (!canDepositOrWithdraw) {
            return DepositProps({canDeposit: false, token: address(0), shares: 0});
        }
        ERC20 depositToken = ERC20(token);
        uint256 rebalancerTokenBalance = depositToken.balanceOf(address(this));
        uint256 sharesSypply = s.sharesToken.totalSupply();
        uint256 sharesToMint = sharesSypply > 0
            ? amount.mulDiv(sharesSypply, rebalancerTokenBalance)
            : initSharesToMint();

        return DepositProps({canDeposit: true, token: token, shares: sharesToMint});
    }

    function deposit(uint256 amount) external nonReentrant {
        DepositProps memory dp = previewDeposit(amount);
        if (!dp.canDeposit) {
            revert DepositForbidden();
        } else {
            ERC20(dp.token).transferFrom(msg.sender, address(this), amount);
            s.sharesToken.mintTo(msg.sender, dp.shares);
        }
    }

    function previewRedeem(uint256 shares) public view returns (RedeemProps memory) {
        (bool canDepositOrWithdraw, address token) = _previewOperation();
        if (!canDepositOrWithdraw) {
            return RedeemProps({canRedeem: false, token: address(0), amount: 0});
        }
        ERC20 redeemToken = ERC20(token);
        uint256 rebalancerTokenBalance = redeemToken.balanceOf(address(this));
        uint256 sharesSypply = s.sharesToken.totalSupply();
        uint256 redeemAmount =
            sharesSypply > 0 ? shares.mulDiv(rebalancerTokenBalance, sharesSypply) : 0;

        return RedeemProps({canRedeem: true, token: token, amount: redeemAmount});
    }

    function redeem(uint256 shares) external nonReentrant {
        RedeemProps memory rp = previewRedeem(shares);
        if (!rp.canRedeem) {
            revert RedeemForbidden();
        } else {
            s.sharesToken.burnFrom(msg.sender, shares);
            ERC20(rp.token).transfer(msg.sender, rp.amount);
        }
    }

    function previewSwap() public view returns (SwapProps memory) {
        // h = usd
        // e = eth
        // hPrice = 0.1 e
        // ePrice = 10 h

        uint256 hPrice = s.oracle.getHedgePrice(s.exposureToken.decimals());
        uint256 ePrice = s.oracle.getExposurePrice(s.hedgeToken.decimals());

        // rebalanceExposurePrice = 0.05 e
        // hedgeEnabled = true
        bool hedgeEnabled = ePrice < s.rebalanceExposurePrice;

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
            rebalanceExposurePrice: s.rebalanceExposurePrice,
            rebType: rebType
        });
    }

    function isHedgeMode() external view returns (bool) {
        return s.oracle.getExposurePrice(s.hedgeToken.decimals()) < s.rebalanceExposurePrice;
    }

    function sharesToken() external view returns (address) {
        return address(s.sharesToken);
    }
}
