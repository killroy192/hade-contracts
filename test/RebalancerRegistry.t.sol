// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {
    RebalancerRegistry,
    IRebalancerRegistryEvents,
    RebalancerNotSupported
} from "src/registry/RebalancerRegistry.sol";
import {MockRebalancer} from "./mocks/MockRebalancer.sol";

contract RebalancerRegistryTest is Test, IRebalancerRegistryEvents {
    RebalancerRegistry private registry;

    MockRebalancer private immutable FIRST_MOCK_REBALANCER = new MockRebalancer();
    MockRebalancer private immutable SECOND_MOCK_REBALANCER = new MockRebalancer();
    address private immutable FAKE_MOCK_REBALANCER = makeAddr("fake-mock-rebalancer");

    function setUp() external {
        registry = new RebalancerRegistry();
    }

    function test_register_unsupported() external {
        vm.expectRevert(abi.encodeWithSelector(RebalancerNotSupported.selector));
        registry.register(FAKE_MOCK_REBALANCER);
    }

    function test_register() external {
        vm.expectEmit(true, false, false, true);
        emit Register(address(FIRST_MOCK_REBALANCER));
        registry.register(address(FIRST_MOCK_REBALANCER));
        vm.expectEmit(true, false, false, true);
        emit Register(address(SECOND_MOCK_REBALANCER));
        registry.register(address(SECOND_MOCK_REBALANCER));
        address[] memory rebalancers = registry.list(address(0), 2);
        assertEq(rebalancers[0], address(FIRST_MOCK_REBALANCER));
        assertEq(rebalancers[1], address(SECOND_MOCK_REBALANCER));
    }
}
