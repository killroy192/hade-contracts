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

    function decimals() public pure returns (uint8) {
        return 16;
    }

    function getHedgePrice() external view returns (uint256) {
        return uint256(1 * 10 ** decimals()).mulDiv(10 ** decimals(), getExposurePrice());
    }

    function getExposurePrice() public view returns (uint256) {
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

        uint256 price = answer.toUint256();

        if (price <= 0) {
            revert ForbiddenValue(price);
        }

        return price.scale(dataFeed.decimals(), decimals());
    }
}
