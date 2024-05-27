// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {
    Rebalancer,
    Config,
    SharesToken,
    ERC20,
    SerializedState,
    RTypes,
    OperationProps
} from "src/rebalancer/Rebalancer.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockRegistry} from "./mocks/MockRegistry.sol";

contract RebalancerTest is Test {
    SharesToken private exposureToken = new SharesToken("mockWETH", "mWETH");
    SharesToken private hedgeToken = new SharesToken("mockUSD", "mUSD");
    MockOracle private oracle = new MockOracle();
    MockRegistry private registry = new MockRegistry();

    Rebalancer private rebalancer;
    Config private config = Config({
        exposureToken: address(exposureToken),
        hedgeToken: address(hedgeToken),
        oracle: address(oracle),
        registry: address(registry),
        multiplier: 1001 * 10 ** 5, // 1.001 -> 0.1% premium
        rebalanceExposurePrice: oracle.getExposurePrice(hedgeToken.decimals())
    });

    address private immutable ALICE = makeAddr("alice");
    address private immutable BOB = makeAddr("alice");
    uint256 private initExposureBalance = 10 * 10 ** exposureToken.decimals();
    uint256 private initHedgeBalance = 10 * config.rebalanceExposurePrice;

    function setUp() external {
        rebalancer = new Rebalancer(config);
        exposureToken.mintTo(ALICE, initExposureBalance);
        hedgeToken.mintTo(ALICE, initHedgeBalance);
        exposureToken.mintTo(BOB, initExposureBalance);
        hedgeToken.mintTo(BOB, initHedgeBalance);
    }

    function _hedgeModeOn() private {
        oracle.setPrice(oracle.rawPrice() / 2);
    }

    function _hedgeModeOff() private {
        oracle.setPrice(config.rebalanceExposurePrice / 10 ** hedgeToken.decimals());
    }

    function test_decimals() external {
        assertEq(rebalancer.decimals(), 8);
    }

    function test_isHedgeMode() external {
        assertEq(rebalancer.isHedgeMode(), false);
        _hedgeModeOn();
        assertEq(rebalancer.isHedgeMode(), true);
    }

    function test_state() external {
        SerializedState memory state = rebalancer.state();
        assertEq(state.exposureToken, config.exposureToken);
        assertEq(state.hedgeToken, config.hedgeToken);
        assertEq(state.oracle, config.oracle);
        assertEq(state.multiplier, config.multiplier);
        assertEq(state.rebalanceExposurePrice, config.rebalanceExposurePrice);
        assert(state.rebType == RTypes.Tick);
        assertEq(SharesToken(state.sharesToken).name(), "hdmWETH_mUSD_tick");
    }

    function test_previewOperationInitial() external {
        OperationProps memory op = rebalancer.previewOperation();
        assertEq(op.canDepositOrWithdraw, true);
        assertEq(op.opToken, config.exposureToken);
        _hedgeModeOn();
        op = rebalancer.previewOperation();
        assertEq(op.canDepositOrWithdraw, true);
        assertEq(op.opToken, config.hedgeToken);
    }

    function test_deposit() external {
        OperationProps memory op = rebalancer.previewOperation();
        vm.startPrank(ALICE);
        ERC20 eToken = ERC20(op.opToken);
        uint256 depositAmount = 1 * 10 ** eToken.decimals();
        eToken.approve(address(rebalancer), depositAmount);
        rebalancer.deposit(depositAmount);
        vm.stopPrank();
        assertEq(eToken.balanceOf(address(rebalancer)), depositAmount);
        assertEq(eToken.balanceOf(ALICE), initExposureBalance - depositAmount);
        assertEq(
            SharesToken(rebalancer.sharesToken()).balanceOf(ALICE), rebalancer.initSharesToMint()
        );
    }
}
