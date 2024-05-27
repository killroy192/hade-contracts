// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error BalancerNotSupported();

interface IRegistryEvents {
    event Register(address indexed balancer);
    event UnRegister(address indexed balancer);
}

interface IRegistry {
    function register(address balancer) external;

    function unRegister(address balancer) external;

    function list(address head, uint256 amount) external view returns (address[] memory);
}
