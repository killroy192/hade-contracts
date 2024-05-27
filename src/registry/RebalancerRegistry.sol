// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {LinkedList, LinkedListLibrary} from "./libs/LinkedList.sol";
import {
    IRebalancerRegistry,
    IRebalancerRegistryEvents,
    RebalancerNotSupported
} from "./RebalancerRegistry.types.sol";
import {IRebalancer} from "src/rebalancer/Rebalancer.types.sol";

contract RebalancerRegistry is IRebalancerRegistry, IRebalancerRegistryEvents {
    using LinkedListLibrary for LinkedList;
    using ERC165Checker for address;

    LinkedList private rebalancers;

    modifier onlyRebalancerContract(address rebalancer) {
        if (
            !rebalancer.supportsERC165()
                || !rebalancer.supportsInterface(type(IRebalancer).interfaceId)
        ) {
            revert RebalancerNotSupported();
        }
        _;
    }

    function register(address rebalancer) external onlyRebalancerContract(rebalancer) {
        rebalancers.push(rebalancer);
        emit Register(rebalancer);
    }

    function unRegister(address rebalancer) external {
        rebalancers.remove(rebalancer);
        emit UnRegister(rebalancer);
    }

    function list(address head, uint256 amount) external view returns (address[] memory) {
        return rebalancers.toList(head, amount);
    }
}
