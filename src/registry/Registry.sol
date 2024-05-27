// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {LinkedList, LinkedListLibrary} from "./libs/LinkedList.sol";
import {IRegistry, IRegistryEvents, BalancerNotSupported} from "./Registry.types.sol";
import {IBalancer} from "src/balancer/Balancer.types.sol";

contract Registry is IRegistry, IRegistryEvents {
    using LinkedListLibrary for LinkedList;
    using ERC165Checker for address;

    LinkedList private balancers;

    modifier onlyBalancerContract(address balancer) {
        if (!balancer.supportsInterface(type(IBalancer).interfaceId)) {
            revert BalancerNotSupported();
        }
        _;
    }

    function register(address balancer) external onlyBalancerContract(balancer) {
        balancers.push(balancer);
        emit Register(balancer);
    }

    function unRegister(address balancer) external {
        balancers.remove(balancer);
        emit UnRegister(balancer);
    }

    function list(address head, uint256 amount) external view returns (address[] memory) {
        return balancers.toList(head, amount);
    }
}
