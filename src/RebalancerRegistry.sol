// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LinkedList, LinkedListLibrary} from "src/libs/LinkedList.sol";

import {IRebalancerRegistry} from "src/RebalancerRegistry.types.sol";

contract RebalancerRegistry is IRebalancerRegistry {
    using LinkedListLibrary for LinkedList;

    LinkedList private rebalancers;

    function register(address rebalancer) external {
        rebalancers.push(rebalancer);
    }

    function unRegister(address rebalancer) external {
        rebalancers.remove(rebalancer);
    }

    function list(address head, uint256 amount) external view returns (address[] memory) {
        return rebalancers.toList(head, amount);
    }
}
