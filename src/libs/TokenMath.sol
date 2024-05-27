// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library TokenMath {
    using Math for uint256;

    function scale(uint256 value, uint8 fromDec, uint8 toDec) internal pure returns (uint256) {
        if (fromDec < toDec) {
            return value * 10 ** uint256(toDec - fromDec);
        } else if (fromDec > toDec) {
            return value.mulDiv(1, 10 ** uint256(fromDec - toDec));
        }
        return value;
    }
}
