// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library TestUtils {
    function powDec(uint256 value, uint8 decimals) external pure returns (uint256) {
        return value * 10 ** decimals;
    }

    function conv(IERC20Metadata token, uint256 value) external view returns (uint256) {
        return value * 10 ** token.decimals();
    }
}
