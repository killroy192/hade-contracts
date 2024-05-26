// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error ForbiddenValue(uint256 answer);

enum StrikeTypes {
    Classic,
    UpOnly
}

interface IStrikeOracle {
    function decimals() external pure returns (uint256);
    // oracle defines how to set strike
    function getStrike(uint256 prevStrike) external view returns (uint256);

    function getStrikeType() external view returns (StrikeTypes);
}
