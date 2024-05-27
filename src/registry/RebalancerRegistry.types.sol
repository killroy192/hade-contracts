// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IRebalancerRegistry {
    function register(address rebalancer) external;

    function unRegister(address rebalancer) external;

    function list(address head, uint256 amount) external view returns (address[] memory);
}
