// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error ForbiddenValue(uint256 answer);

interface IOracle {
    function getHedgePrice() external view returns (uint256);
    function getExposurePrice() external view returns (uint256);
}
