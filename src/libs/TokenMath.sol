// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStrikeOracle} from "src/strikeOracle/StrikeOracle.types.sol";

library TokenMath {
    using Math for uint256;

    function scale(uint256 value, uint256 token0Dec, uint256 token1Dec)
        internal
        pure
        returns (uint256)
    {
        if (token0Dec < token1Dec) {
            return value * 10 ** uint256(token1Dec - token0Dec);
        } else if (token0Dec > token1Dec) {
            return value.mulDiv(1, 10 ** uint256(token0Dec - token1Dec));
        }
        return value;
    }

    function convert(uint256 token0, uint256 amount, address oracle)
        internal
        pure
        returns (uint256)
    {
        return token0.mulDiv(amount, 10 ** IStrikeOracle(oracle).decimals());
    }
}
