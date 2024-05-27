// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {
    Rebalancer,
    Config,
    SharesToken,
    ERC20,
    SerializedState,
    RTypes,
    DepositProps,
    DepositForbidden,
    RedeemProps,
    RedeemForbidden
} from "src/rebalancer/Rebalancer.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockRegistry} from "./mocks/MockRegistry.sol";

contract RebalancerTest is Test {
    using Math for uint8;

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
    address private immutable BOB = makeAddr("BOB");
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

    function _deposit(address user, uint256 amount)
        private
        returns (ERC20 token, uint256 depositAmount)
    {
        DepositProps memory dp = rebalancer.previewDeposit(amount);
        token = ERC20(dp.token);
        vm.startPrank(user);
        depositAmount = amount * 10 ** token.decimals();
        token.approve(address(rebalancer), depositAmount);
        rebalancer.deposit(depositAmount);
        vm.stopPrank();
    }

    function test_deposit() external {
        (ERC20 token, uint256 depositAmount) = _deposit(ALICE, 1);
        assertEq(token.balanceOf(address(rebalancer)), depositAmount);
        assertEq(token.balanceOf(ALICE), initExposureBalance - depositAmount);
        assertEq(
            SharesToken(rebalancer.sharesToken()).balanceOf(ALICE), rebalancer.initSharesToMint()
        );
    }

    function testFuzz_twoDeposits(uint8 aliceAmount, uint8 bobAmount) external {
        vm.assume(aliceAmount > 0 && aliceAmount <= 10 && bobAmount > 0 && bobAmount <= 10);
        (ERC20 token, uint256 aliceDeposit) = _deposit(ALICE, aliceAmount);
        (, uint256 bobDeposit) = _deposit(BOB, bobAmount);
        assertEq(token.balanceOf(address(rebalancer)), aliceDeposit + bobDeposit);
        assertEq(token.balanceOf(ALICE), initExposureBalance - aliceDeposit);
        assertEq(token.balanceOf(BOB), initExposureBalance - bobDeposit);
        assertEq(
            SharesToken(rebalancer.sharesToken()).balanceOf(ALICE), rebalancer.initSharesToMint()
        );
        assertEq(
            SharesToken(rebalancer.sharesToken()).balanceOf(BOB),
            bobAmount.mulDiv(rebalancer.initSharesToMint(), aliceAmount)
        );
    }

    function test_previewDeposit_unbalanced() external {
        (, uint256 depositAmount) = _deposit(ALICE, 1);
        _hedgeModeOn();
        DepositProps memory dp = rebalancer.previewDeposit(depositAmount);
        assertEq(dp.canDeposit, false);
        assertEq(dp.token, address(0));
    }

    function test_deposit_unbalanced() external {
        (ERC20 token, uint256 depositAmount) = _deposit(ALICE, 1);
        _hedgeModeOn();
        vm.startPrank(ALICE);
        token.approve(address(rebalancer), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(DepositForbidden.selector));
        rebalancer.deposit(depositAmount);
        vm.stopPrank();
    }

    function _redeem(address user, uint256 shares)
        private
        returns (ERC20 token, uint256 redeemAmount)
    {
        RedeemProps memory rp = rebalancer.previewRedeem(shares);
        token = ERC20(rp.token);
        vm.startPrank(user);
        redeemAmount = rp.amount;
        SharesToken(rebalancer.sharesToken()).approve(address(rebalancer), shares);
        rebalancer.redeem(shares);
        vm.stopPrank();
    }

    function test_redeem() external {
        SharesToken sharesToken = SharesToken(rebalancer.sharesToken());
        _deposit(ALICE, 1);
        (ERC20 token,) = _redeem(ALICE, sharesToken.balanceOf(ALICE));
        assertEq(token.balanceOf(address(rebalancer)), 0);
        assertEq(token.balanceOf(ALICE), initExposureBalance);
        assertEq(sharesToken.balanceOf(ALICE), 0);
        assertEq(sharesToken.totalSupply(), 0);
    }

    function test_previewRedeem_unbalanced() external {
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SharesToken sharesToken = SharesToken(rebalancer.sharesToken());
        RedeemProps memory rp = rebalancer.previewRedeem(sharesToken.balanceOf(ALICE));
        assertEq(rp.canRedeem, false);
        assertEq(rp.token, address(0));
    }

    function test_redeem_unbalanced() external {
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SharesToken sharesToken = SharesToken(rebalancer.sharesToken());
        uint256 aliceShares = sharesToken.balanceOf(ALICE);
        vm.startPrank(ALICE);
        sharesToken.approve(address(rebalancer), aliceShares);
        vm.expectRevert(abi.encodeWithSelector(RedeemForbidden.selector));
        rebalancer.redeem(aliceShares);
        vm.stopPrank();
    }
}
