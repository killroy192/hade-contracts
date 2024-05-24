// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library LedgerLib {
    struct OutputUTXO {
        uint256 value;
        bytes32 utxoRoot;
    }

    /**
     * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
     * сopy from: v5.0.1 OpenZeppelin MerkleProof.sol
     */
    function efficientHash(bytes32 proofSecret, bytes32 spendSecret)
        public
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        // solhint-disable no-inline-assembly
        assembly {
            mstore(0x00, proofSecret)
            mstore(0x20, spendSecret)
            value := keccak256(0x00, 0x40)
        }
    }

    function createCommitHash(OutputUTXO[] calldata ouputs, bytes32 utxoRoot)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(ouputs, utxoRoot));
    }
}
