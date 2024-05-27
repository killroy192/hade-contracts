// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";
import "forge-std/console.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {
    IBalancer,
    Balancer,
    Config,
    SharesToken,
    ERC20,
    SerializedState,
    BTypes,
    DepositProps,
    DepositForbidden,
    RedeemProps,
    RedeemForbidden,
    SwapProps,
    SwapForbidden
} from "src/balancer/Balancer.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockRegistry} from "./mocks/MockRegistry.sol";

contract BalancerTest is Test {
    using Math for uint8;

    SharesToken private exposureToken = new SharesToken("mockWETH", "mWETH");
    SharesToken private hedgeToken = new SharesToken("mockUSD", "mUSD");
    MockOracle private oracle = new MockOracle();
    MockRegistry private registry = new MockRegistry();

    Balancer private balancer;
    Config private config = Config({
        exposureToken: address(exposureToken),
        hedgeToken: address(hedgeToken),
        oracle: address(oracle),
        multiplier: 1001 * 10 ** 11, // 1.001 -> 0.1% premium
        rebalanceExposurePrice: oracle.getExposurePrice(hedgeToken.decimals())
    });

    address private immutable ALICE = makeAddr("alice");
    address private immutable BOB = makeAddr("BOB");
    uint256 private initExposureBalance = 10 * 10 ** exposureToken.decimals();
    uint256 private initHedgeBalance = initExposureBalance * config.rebalanceExposurePrice;

    function setUp() external {
        balancer = new Balancer(config);
        registry.register(address(balancer));
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
        assertEq(balancer.decimals(), 8);
    }

    function test_isHedgeMode() external {
        assertEq(balancer.isHedgeMode(), false);
        _hedgeModeOn();
        assertEq(balancer.isHedgeMode(), true);
    }

    function test_state() external {
        SerializedState memory state = balancer.state();
        assertEq(state.exposureToken, config.exposureToken);
        assertEq(state.hedgeToken, config.hedgeToken);
        assertEq(state.oracle, config.oracle);
        assertEq(state.multiplier, config.multiplier);
        assertEq(state.rebalanceExposurePrice, config.rebalanceExposurePrice);
        assert(state.rebType == BTypes.Tick);
        assertEq(SharesToken(state.sharesToken).name(), "hdmWETH_mUSD_tick");
    }

    function _deposit(address user, uint256 amount)
        private
        returns (ERC20 token, uint256 depositAmount)
    {
        DepositProps memory dp = balancer.previewDeposit(amount);
        token = ERC20(dp.token);
        vm.startPrank(user);
        depositAmount = amount * 10 ** token.decimals();
        token.approve(address(balancer), depositAmount);
        balancer.deposit(depositAmount);
        vm.stopPrank();
    }

    function test_deposit() external {
        (ERC20 token, uint256 depositAmount) = _deposit(ALICE, 1);
        assertEq(token.balanceOf(address(balancer)), depositAmount);
        assertEq(token.balanceOf(ALICE), initExposureBalance - depositAmount);
        assertEq(SharesToken(balancer.sharesToken()).balanceOf(ALICE), balancer.initSharesToMint());
    }

    function testFuzz_twoDeposits(uint8 aliceAmount, uint8 bobAmount) external {
        vm.assume(aliceAmount > 0 && aliceAmount <= 10 && bobAmount > 0 && bobAmount <= 10);
        (ERC20 token, uint256 aliceDeposit) = _deposit(ALICE, aliceAmount);
        (, uint256 bobDeposit) = _deposit(BOB, bobAmount);
        assertEq(token.balanceOf(address(balancer)), aliceDeposit + bobDeposit);
        assertEq(token.balanceOf(ALICE), initExposureBalance - aliceDeposit);
        assertEq(token.balanceOf(BOB), initExposureBalance - bobDeposit);
        assertEq(SharesToken(balancer.sharesToken()).balanceOf(ALICE), balancer.initSharesToMint());
        assertEq(
            SharesToken(balancer.sharesToken()).balanceOf(BOB),
            bobAmount.mulDiv(balancer.initSharesToMint(), aliceAmount)
        );
    }

    function test_previewDeposit_unbalanced() external {
        (, uint256 depositAmount) = _deposit(ALICE, 1);
        _hedgeModeOn();
        DepositProps memory dp = balancer.previewDeposit(depositAmount);
        assertEq(dp.canDeposit, false);
        assertEq(dp.token, address(0));
    }

    function test_deposit_unbalanced() external {
        (ERC20 token, uint256 depositAmount) = _deposit(ALICE, 1);
        _hedgeModeOn();
        vm.startPrank(ALICE);
        token.approve(address(balancer), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(DepositForbidden.selector));
        balancer.deposit(depositAmount);
    }

    function _redeem(address user, uint256 shares)
        private
        returns (ERC20 token, uint256 redeemAmount)
    {
        RedeemProps memory rp = balancer.previewRedeem(shares);
        token = ERC20(rp.token);
        vm.startPrank(user);
        redeemAmount = rp.amount;
        SharesToken(balancer.sharesToken()).approve(address(balancer), shares);
        balancer.redeem(shares);
        vm.stopPrank();
    }

    function test_redeem() external {
        SharesToken sharesToken = SharesToken(balancer.sharesToken());
        _deposit(ALICE, 1);
        (ERC20 token,) = _redeem(ALICE, sharesToken.balanceOf(ALICE));
        assertEq(token.balanceOf(address(balancer)), 0);
        assertEq(token.balanceOf(ALICE), initExposureBalance);
        assertEq(sharesToken.balanceOf(ALICE), 0);
        assertEq(sharesToken.totalSupply(), 0);
    }

    function test_previewRedeem_unbalanced() external {
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SharesToken sharesToken = SharesToken(balancer.sharesToken());
        RedeemProps memory rp = balancer.previewRedeem(sharesToken.balanceOf(ALICE));
        assertEq(rp.canRedeem, false);
        assertEq(rp.token, address(0));
    }

    function test_redeem_unbalanced() external {
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SharesToken sharesToken = SharesToken(balancer.sharesToken());
        uint256 aliceShares = sharesToken.balanceOf(ALICE);
        vm.startPrank(ALICE);
        sharesToken.approve(address(balancer), aliceShares);
        vm.expectRevert(abi.encodeWithSelector(RedeemForbidden.selector));
        balancer.redeem(aliceShares);
    }

    function test_previewSwap() external {
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SwapProps memory sp = balancer.previewSwap(0);
        assertEq(sp.tokenBalancerSell, config.exposureToken);
        assertEq(sp.tokenBalancerBuy, config.hedgeToken);
        assertEq(sp.sellPrice, 499500499500499);
        assertEq(sp.amountToCollect, 0);
    }

    function testFuzz_swapp(uint256 amountUserBuy) external {
        vm.assume(amountUserBuy <= exposureToken.balanceOf(ALICE));
        _deposit(ALICE, 1);
        _hedgeModeOn();
        SwapProps memory sp = balancer.previewSwap(amountUserBuy);
        ERC20 tokenBalancerSell = ERC20(sp.tokenBalancerSell);
        uint256 totalSypplyToSell = tokenBalancerSell.balanceOf(address(balancer));
        vm.startPrank(ALICE);
        hedgeToken.approve(address(balancer), hedgeToken.balanceOf(ALICE));
        if (totalSypplyToSell < amountUserBuy) {
            vm.expectRevert(abi.encodeWithSelector(SwapForbidden.selector));
            balancer.swap(amountUserBuy);
        } else if (totalSypplyToSell == amountUserBuy) {
            balancer.swap(amountUserBuy);
            assertEq(tokenBalancerSell.balanceOf(address(balancer)), 0);
        } else {
            balancer.swap(amountUserBuy);
            uint256 currentSupply = tokenBalancerSell.balanceOf(address(balancer));
            assertLe(currentSupply, totalSypplyToSell);
            assertLe(0, currentSupply);
        }
    }
}
