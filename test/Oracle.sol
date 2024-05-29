// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Oracle} from "src/oracle/Oracle.sol";
import {MockChainlinkFeed} from "./mocks/MockChainlinkFeed.sol";

contract OracleTest is Test {
    using Math for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeCast for int32;

    Oracle private oracle;
    MockChainlinkFeed private feed = new MockChainlinkFeed();
    uint8 private expDec = 8;
    uint8 private hedgeDec = 16;

    function setUp() external {
        oracle = new Oracle(address(feed));
    }

    function testFuzz_getExposurePriceError(int32 answer) external {
        vm.assume(answer <= 0);
        feed.setAnswer(answer);
        vm.expectRevert();
        oracle.getExposurePrice(expDec);
    }

    function test_getExposurePrice() external {
        feed.setAnswer(int32(1000));
        uint256 expRes = 1000 * 10 ** expDec; // 100000000000
        assertEq(oracle.getExposurePrice(expDec), expRes);
    }

    function testFuzz_getExposurePrice(int32 answer) external {
        vm.assume(answer > 0);
        feed.setAnswer(answer);
        uint256 expResult = answer.toUint256() * 10 ** expDec;
        assertEq(oracle.getExposurePrice(expDec), expResult);
    }

    function testFuzz_getHedgePriceError(int32 answer) external {
        vm.assume(answer <= 0);
        feed.setAnswer(answer);
        vm.expectRevert();
        oracle.getHedgePrice(hedgeDec);
    }

    function test_getHedgePrice() external {
        feed.setAnswer(int32(1000));
        uint256 expRes = 10 ** (hedgeDec - 3); // 10000000000000
        assertEq(oracle.getHedgePrice(hedgeDec), expRes);
    }

    function testFuzz_getHedgePrice(int32 answer) external {
        vm.assume(answer > 0);
        feed.setAnswer(answer);
        // 1 / exposurePrice
        uint256 expResult =
            uint256(1 * 10 ** hedgeDec).mulDiv(10 ** hedgeDec, answer.toUint256() * 10 ** hedgeDec);
        assertEq(oracle.getHedgePrice(hedgeDec), expResult);
    }
}
