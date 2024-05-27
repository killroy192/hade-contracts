// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SharesToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {}

    function burnFrom(address account, uint256 value) external onlyOwner {
        _burn(account, value);
    }

    function mintTo(address account, uint256 value) external onlyOwner {
        _mint(account, value);
    }
}
