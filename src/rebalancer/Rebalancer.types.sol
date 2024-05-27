// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error DepositAndWithdrawForbidden();
error SwapForbidden();

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
    uint256 rebalanceHedgePrice;
    RTypes rebType;
}

interface IRebalancer {
    function decimals() external pure returns (uint8);

    function previewSwap() external view returns (SwapProps memory);

    function swap(uint256 amountToBuy) external;

    function previewOperation() external view returns (OperationProps memory);

    function deposit(uint256 amount) external;

    function redeem(uint256 shares) external;

    /**
     * dev utils
     */
    function state() external view returns (SerializedState memory);

    function isHedgeMode() external view returns (bool);
}
