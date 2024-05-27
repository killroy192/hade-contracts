// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error ForbiddenValue(int256 answer);

interface IOracle {
    function getHedgePrice(uint8 dec) external view returns (uint256);
    function getExposurePrice(uint8 dec) external view returns (uint256);
}
