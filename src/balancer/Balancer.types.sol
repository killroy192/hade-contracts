// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error DepositForbidden();
error RedeemForbidden();
error SwapForbidden();

struct SwapProps {
    address tokenBalancerSell;
    address tokenBalancerBuy;
    uint256 sellPrice;
    uint256 amountToCollect;
}

struct DepositProps {
    bool canDeposit;
    address token;
    uint256 shares;
}

struct RedeemProps {
    bool canRedeem;
    address token;
    uint256 amount;
}

struct Config {
    address exposureToken;
    address hedgeToken;
    address oracle;
    uint256 multiplier;
    uint256 rebalanceExposurePrice;
}

enum BTypes {
    Tick,
    PeriodTick,
    UpOnlyTick
}

struct SerializedState {
    address exposureToken;
    address hedgeToken;
    address sharesToken;
    address oracle;
    uint256 multiplier;
    uint256 rebalanceExposurePrice;
    BTypes rebType;
}

interface IBalancer {
    function decimals() external pure returns (uint8);

    function initSharesToMint() external pure returns (uint256);

    function previewDeposit(uint256 amount) external view returns (DepositProps memory);

    function deposit(uint256 amount) external;

    function previewRedeem(uint256 shares) external view returns (RedeemProps memory);

    function redeem(uint256 shares) external;

    function previewSwap(uint256 amountUserBuy) external view returns (SwapProps memory);

    function swap(uint256 amountUserBuy) external;

    function state() external view returns (SerializedState memory);

    function isHedgeMode() external view returns (bool);

    function sharesToken() external view returns (address);
}
