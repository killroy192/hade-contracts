// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {HadeToken} from "src/HadeToken.sol";

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

interface IMarketManager {
    function marketId(MarketConfig calldata config) external pure returns (bytes32);

    function getMarket(bytes32 id) external view returns (Market memory);

    function getShares(bytes32 id, address owner) external view returns (uint256);

    function getPosition(bytes32 id, address owner) external view returns (uint256);

    function create(MarketConfig calldata config) external returns (bytes32 id);

    function mint(bytes32 id, uint256 token0Amount) external;

    function redeem(bytes32 id, uint256 token0Amount, address token) external;
}
