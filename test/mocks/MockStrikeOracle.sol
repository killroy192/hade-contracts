// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IStrikeOracle, StrikeTypes} from "src/strikeOracle/StrikeOracle.types.sol";
import {TestUtils} from "../TestUtils.sol";

contract MockStrikeOracle is IStrikeOracle {
    StrikeTypes private _stType = StrikeTypes.Classic;
    uint256 private _strike = 1000;

    function decimals() public pure returns (uint8) {
        return 16;
    }

    function getStrike(uint256) external view returns (uint256) {
        return TestUtils.to256dec(_strike, decimals());
    }

    function getStrike() external view returns (uint256) {
        return TestUtils.to256dec(_strike, decimals());
    }

    function setStrike(uint256 newStrike) external {
        _strike = newStrike;
    }

    function getStrikeType() external view returns (StrikeTypes) {
        return _stType;
    }

    function setStrikeType(StrikeTypes stType) external {
        _stType = stType;
    }
}
