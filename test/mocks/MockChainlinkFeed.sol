// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract MockChainlinkFeed {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeCast for int8;

    int256 private _answer = (1000 * 10 ** decimals()).toInt256();

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = uint80(10);
        answer = _answer;
        startedAt = uint256(1000);
        updatedAt = uint256(1000);
        answeredInRound = uint80(10);
    }

    function setAnswer(int32 exposurePrice) external {
        _answer = int256(exposurePrice * (10 ** decimals()).toInt256());
    }
}
