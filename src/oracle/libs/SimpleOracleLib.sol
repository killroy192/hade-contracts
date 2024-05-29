// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error ForbiddenValue(int256 answer);

library SimpleOracleLib {
    using Math for uint256;
    using SafeCast for int256;

    function scale(uint256 value, uint8 fromDec, uint8 toDec) public pure returns (uint256) {
        if (fromDec < toDec) {
            return value * 10 ** uint256(toDec - fromDec);
        } else if (fromDec > toDec) {
            return value.mulDiv(1, 10 ** uint256(fromDec - toDec));
        }
        return value;
    }

    function inversePrice(AggregatorV3Interface dataFeed, uint8 dec)
        external
        view
        returns (uint256)
    {
        return uint256(1 * 10 ** dec).mulDiv(10 ** dec, price(dataFeed, dec));
    }

    function price(AggregatorV3Interface dataFeed, uint8 dec) public view returns (uint256) {
        (
            /* uint80 roundID */
            ,
            int256 answer,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        if (answer <= 0) {
            revert ForbiddenValue(answer);
        }

        return scale(answer.toUint256(), dataFeed.decimals(), dec);
    }
}
