// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IStrikeOracle, StrikeTypes, ForbiddenValue} from "./StrikeOracle.types.sol";

import {TokenMath} from "src/libs/TokenMath.sol";

contract StrikeOracle is IStrikeOracle {
    using SafeCast for int256;
    using TokenMath for uint256;

    AggregatorV3Interface private dataFeed;
    StrikeTypes private strikeType;

    constructor(address chainlinkDataFeedFeed, StrikeTypes _strikeType) {
        dataFeed = AggregatorV3Interface(chainlinkDataFeedFeed);
        strikeType = _strikeType;
    }

    function decimals() public pure returns (uint8) {
        return 16;
    }

    function getStrike(uint256 prevStrike) external view returns (uint256) {
        uint256 formattedPrice = getStrike();

        if (strikeType == StrikeTypes.UpOnly) {
            return prevStrike < formattedPrice ? formattedPrice : prevStrike;
        }
        return formattedPrice;
    }

    function getStrike() public view returns (uint256) {
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

    function getStrikeType() external view returns (StrikeTypes) {
        return strikeType;
    }
}
