// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IOracle, ForbiddenValue} from "./Oracle.types.sol";

import {TokenMath} from "src/libs/TokenMath.sol";

contract Oracle is IOracle {
    using SafeCast for int256;
    using TokenMath for uint256;
    using Math for uint256;

    AggregatorV3Interface private dataFeed;

    constructor(address chainlinkDataFeedFeed) {
        dataFeed = AggregatorV3Interface(chainlinkDataFeedFeed);
    }

    function getHedgePrice(uint8 dec) external view returns (uint256) {
        return uint256(1 * 10 ** dec).mulDiv(10 ** dec, getExposurePrice(dec));
    }

    function getExposurePrice(uint8 dec) public view returns (uint256) {
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

        uint256 price = answer.toUint256();

        return price.scale(dataFeed.decimals(), dec);
    }
}
