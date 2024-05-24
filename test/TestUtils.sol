// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library TestUtils {
    function to256dec(uint256 value, uint8 decimals) external pure returns (uint256) {
        return value * 10 ** decimals;
    }

    function conv(IERC20Metadata token, uint256 value) external view returns (uint256) {
        return value * 10 ** token.decimals();
    }

    /**
     * @dev Sorts the pair (a, b) and hashes the result.
     * сopy from: v5.0.1 OpenZeppelin MerkleProof.sol
     */
    function hashPair(bytes32 a, bytes32 b) external pure returns (bytes32) {
        return a < b ? efficientHash(a, b) : efficientHash(b, a);
    }

    /**
     * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
     * сopy from: v5.0.1 OpenZeppelin MerkleProof.sol
     */
    function efficientHash(bytes32 a, bytes32 b) public pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
