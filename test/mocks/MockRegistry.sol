// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IRegistry} from "src/registry/Registry.types.sol";

contract MockRegistry is IRegistry {
    function register(address balancer) external {}

    function unRegister(address balancer) external {}

    function list(address head, uint256 amount) external view returns (address[] memory) {}
}
