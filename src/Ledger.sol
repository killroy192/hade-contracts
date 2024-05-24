// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error CommitedUTXO(bytes32 utxoRoot);
error UTXONotFound(bytes32 utxoRoot);
error InvalidSecret(bytes32 utxoRoot, bytes32 secret);
error FailedTransaction();
error DepositToSmall(uint256 amount);

contract Ledger is ReentrancyGuard {
    mapping(bytes32 => uint256) private UTXO;

    function balanceOf(bytes32 utxoRoot) public view returns (uint256) {
        return UTXO[utxoRoot];
    }

    function deposit(bytes32 utxoRoot) external payable returns (bool) {
        if (balanceOf(utxoRoot) != 0) {
            revert CommitedUTXO(utxoRoot);
        }
        if (msg.value == 0) {
            revert DepositToSmall(msg.value);
        }
        UTXO[utxoRoot] = msg.value;
        return true;
    }

    function withdraw(
        bytes32[] calldata proof,
        bytes32 utxoRoot,
        bytes32 secret,
        address payable recepient
    ) external nonReentrant returns (bool) {
        if (balanceOf(utxoRoot) == 0) {
            revert UTXONotFound(utxoRoot);
        }
        if (!MerkleProof.verifyCalldata(proof, utxoRoot, keccak256(abi.encode(secret)))) {
            revert InvalidSecret(utxoRoot, secret);
        }
        (bool sentStatus,) = recepient.call{value: UTXO[utxoRoot]}("");
        if (!sentStatus) {
            revert FailedTransaction();
        }
        delete UTXO[utxoRoot];
        return sentStatus;
    }
}
