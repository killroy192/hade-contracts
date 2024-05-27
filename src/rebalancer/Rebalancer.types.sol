// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error DepositForbidden();
error RedeemForbidden();
error SwapForbidden();

struct SwapProps {
    address tokenToSell;
    uint256 maxAmountToSell;
    uint256 sellPrice;
    address tokenToBuy;
    uint256 buyPrice;
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
    address registry;
    uint256 multiplier;
    uint256 rebalanceExposurePrice;
}

enum RTypes {
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
    RTypes rebType;
}

interface IRebalancer {
    function decimals() external pure returns (uint8);

    function initSharesToMint() external pure returns (uint256);

    function previewSwap() external view returns (SwapProps memory);

    function swap(uint256 amountToBuy) external;

    function previewDeposit(uint256 amount) external view returns (DepositProps memory);

    function deposit(uint256 amount) external;

    function previewRedeem(uint256 shares) external view returns (RedeemProps memory);

    function redeem(uint256 shares) external;

    function state() external view returns (SerializedState memory);

    function isHedgeMode() external view returns (bool);

    function sharesToken() external view returns (address);
}
