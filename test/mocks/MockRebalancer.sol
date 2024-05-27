// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IRebalancer} from "src/rebalancer/Rebalancer.types.sol";

contract MockRebalancer is ERC165 {
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IRebalancer).interfaceId || super.supportsInterface(interfaceId);
    }
}
