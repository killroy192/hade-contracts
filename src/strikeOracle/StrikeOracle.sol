// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IStrikeOracle, StrikeTypes, ForbiddenValue} from "./StrikeOracle.types.sol";

contract StrikeOracle is IStrikeOracle {
    using SafeCast for int256;

    AggregatorV3Interface private dataFeed;
    StrikeTypes private strikeType;

    constructor(address chainlinkDataFeedFeed, StrikeTypes _strikeType) {
        dataFeed = AggregatorV3Interface(chainlinkDataFeedFeed);
        strikeType = _strikeType;
    }

    function decimals() public pure returns (uint256) {
        return 16;
    }

    function _scalePrice(uint256 price) private view returns (uint256) {
        uint256 priceDecimals = dataFeed.decimals();
        uint256 dec = decimals();
        if (priceDecimals < dec) {
            return price * 10 ** uint256(dec - priceDecimals);
        } else if (priceDecimals > dec) {
            return price / 10 ** uint256(priceDecimals - dec);
        }
        return price;
    }

    function getStrike(uint256 prevStrike) external view returns (uint256) {
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

        uint256 formattedPrice = _scalePrice(price);

        if (strikeType == StrikeTypes.UpOnly) {
            return prevStrike < formattedPrice ? formattedPrice : prevStrike;
        }
        return formattedPrice;
    }

    function getStrikeType() external view returns (StrikeTypes) {
        return strikeType;
    }
}
