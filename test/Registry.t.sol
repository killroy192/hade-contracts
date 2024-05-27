// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {Registry, IRegistryEvents, BalancerNotSupported} from "src/registry/Registry.sol";
import {MockBalancer} from "./mocks/MockBalancer.sol";

contract RegistryTest is Test, IRegistryEvents {
    Registry private registry;

    MockBalancer private immutable FIRST_MOCK_REBALANCER = new MockBalancer();
    MockBalancer private immutable SECOND_MOCK_REBALANCER = new MockBalancer();
    address private immutable FAKE_MOCK_REBALANCER = makeAddr("fake-mock-balancer");

    function setUp() external {
        registry = new Registry();
    }

    function test_register_unsupported() external {
        vm.expectRevert(abi.encodeWithSelector(BalancerNotSupported.selector));
        registry.register(FAKE_MOCK_REBALANCER);
    }

    function test_register() external {
        vm.expectEmit(true, false, false, true);
        emit Register(address(FIRST_MOCK_REBALANCER));
        registry.register(address(FIRST_MOCK_REBALANCER));
        vm.expectEmit(true, false, false, true);
        emit Register(address(SECOND_MOCK_REBALANCER));
        registry.register(address(SECOND_MOCK_REBALANCER));
        address[] memory balancers = registry.list(address(0), 2);
        assertEq(balancers[0], address(FIRST_MOCK_REBALANCER));
        assertEq(balancers[1], address(SECOND_MOCK_REBALANCER));
    }
}
