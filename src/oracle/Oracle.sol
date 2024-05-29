// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IOracle} from "./Oracle.types.sol";

import {SimpleOracleLib} from "./libs/SimpleOracleLib.sol";

contract Oracle is IOracle {
    using SimpleOracleLib for AggregatorV3Interface;

    AggregatorV3Interface private dataFeed;

    constructor(address chainlinkDataFeedFeed) {
        dataFeed = AggregatorV3Interface(chainlinkDataFeedFeed);
    }

    function getHedgePrice(uint8 dec) external view returns (uint256) {
        return dataFeed.inversePrice(dec);
    }

    function getExposurePrice(uint8 dec) public view returns (uint256) {
        return dataFeed.price(dec);
    }
}
