// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {MarketManager} from "src/MarketManager.sol";
import {
    Market,
    MarketConfig,
    MarketIsNotExist,
    RedeemSession,
    MintSession
} from "src/MarketManager.types.sol";

import {HadeToken} from "src/HadeToken.sol";
import {PeriodsLib} from "src/libs/PeriodsLib.sol";
import {TokenMath} from "src/libs/TokenMath.sol";

import {MockStrikeOracle} from "./mocks/MockStrikeOracle.sol";
import {TestUtils} from "./TestUtils.sol";

contract MarketManagerTest is Test {
    using TokenMath for uint256;

    MarketManager private mmanager;
    HadeToken private token0;
    HadeToken private token1;
    MockStrikeOracle private strikeOracle = new MockStrikeOracle();
    MarketConfig private config;

    address private immutable ALICE = makeAddr("alice");

    function setUp() external {
        mmanager = new MarketManager();
        token0 = new HadeToken("mockWrappedETH", "mWETH");
        token0.mintTo(ALICE, TestUtils.to256dec(1, token0.decimals()));
        token1 = new HadeToken("mockUSDC", "mUSDC");
        token1.mintTo(ALICE, TestUtils.to256dec(1000, token0.decimals()));

        config = MarketConfig({
            token0: address(token0),
            token1: address(token1),
            oracle: address(strikeOracle),
            period: PeriodsLib.WEEK_PERIOD
        });
    }

    function test_create() external {
        bytes32 id = mmanager.create(config);
        assertEq(id, mmanager.marketId(config));
        Market memory m = mmanager.getMarket(id);
        assertEq(m.state.strike, strikeOracle.getStrike());
        assertEq(m.state.lastRoll, block.number);
        assertEq(HadeToken(m.token).name(), "hdmWETH_mUSDC_weekly_classic");
    }

    function test_mint_not_mint_session() external {
        bytes32 id = mmanager.create(config);
        Market memory m = mmanager.getMarket(id);
        vm.roll(m.state.lastRoll + m.config.period - 1);
        vm.expectRevert(abi.encodeWithSelector(RedeemSession.selector));
        mmanager.mint(id, 10);
    }

    function test_mint_not_exist_market() external {
        bytes32 id = keccak256("not_exists");
        vm.expectRevert(abi.encodeWithSelector(MarketIsNotExist.selector));
        mmanager.mint(id, 10);
    }

    function _mint(uint256 token0Amount, uint256 token1Amount) private returns (bytes32) {
        bytes32 id = mmanager.create(config);
        startHoax(ALICE);
        token0.approve(address(mmanager), token0Amount);
        token1.approve(address(mmanager), token1Amount);
        mmanager.mint(id, token0Amount);
        vm.stopPrank();
        return id;
    }

    /**
     * @dev can't use uint256 since overflow
     */
    function testFuzz_mint(uint232 token0Amount) external {
        bytes32 id = mmanager.create(config);
        uint256 token1Amount =
            uint256(token0Amount).convert(strikeOracle.getStrike(), address(strikeOracle));
        startHoax(ALICE);
        token0.approve(address(mmanager), token0Amount);
        token1.approve(address(mmanager), token1Amount);
        if (token0Amount > token0.balanceOf(ALICE)) {
            vm.expectRevert();
        }
        mmanager.mint(id, token0Amount);
        vm.stopPrank();
        if (token0Amount <= token0.balanceOf(ALICE)) {
            Market memory m = mmanager.getMarket(id);
            assertEq(HadeToken(m.token).balanceOf(ALICE), token0Amount);
            assertEq(token0.balanceOf(address(mmanager)), token0Amount);
            assertEq(token1.balanceOf(address(mmanager)), token1Amount);
            assertEq(mmanager.getShares(id, ALICE), token0Amount);
            assertEq(mmanager.getPosition(id, ALICE), 0);
        }
    }

    function test_redeem_not_exis_market() external {
        bytes32 id = keccak256("not_exists");
        vm.expectRevert(abi.encodeWithSelector(MarketIsNotExist.selector));
        mmanager.redeem(id, 0, address(token0));
    }

    function test_redeem_not_redemption_session() external {
        uint256 toMintToken0 = token0.balanceOf(ALICE);
        uint256 toMintToken1 =
            uint256(toMintToken0).convert(strikeOracle.getStrike(), address(strikeOracle));
        bytes32 id = _mint(toMintToken0, toMintToken1);
        Market memory m = mmanager.getMarket(id);
        vm.roll(m.state.lastRoll + m.config.period - PeriodsLib.REDEEM_PERIOD);
        startHoax(ALICE);
        vm.expectRevert(abi.encodeWithSelector(MintSession.selector));
        mmanager.redeem(id, toMintToken0, address(token0));
    }

    /**
     * @dev can't use uint256 since overflow
     */
    function testFuzz_redeem(uint232 toMintToken0) external {
        vm.assume(toMintToken0 <= token0.balanceOf(ALICE));
        uint256 toMintToken1 =
            uint256(toMintToken0).convert(strikeOracle.getStrike(), address(strikeOracle));
        bytes32 id = _mint(toMintToken0, toMintToken1);
        Market memory m = mmanager.getMarket(id);
        vm.roll(m.state.lastRoll + m.config.period);
        startHoax(ALICE);
        m.token.approve(address(mmanager), toMintToken0);
        mmanager.redeem(id, toMintToken0, address(token0));
        vm.stopPrank();
        assertEq(HadeToken(m.token).balanceOf(ALICE), 0);
        assertEq(token0.balanceOf(address(mmanager)), 0);
        assertEq(token0.balanceOf(ALICE), TestUtils.to256dec(1, token0.decimals()));
        assertEq(token1.balanceOf(address(mmanager)), 0);
        assertEq(token1.balanceOf(ALICE), TestUtils.to256dec(1000, token0.decimals()));
        assertEq(mmanager.getShares(id, ALICE), 0);
    }
}
