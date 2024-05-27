// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IBalancer} from "src/balancer/Balancer.types.sol";

contract MockBalancer is ERC165 {
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IBalancer).interfaceId || super.supportsInterface(interfaceId);
    }
}
