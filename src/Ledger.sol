// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {LedgerLib} from "src/LedgerLib.sol";

error CommitedUTXO(bytes32 utxoRoot);
error UTXONotFound(bytes32 utxoRoot);
error FailedTransaction();
error DepositToSmall(uint256 amount);
error CommitmentNotFound();
error InvalidTransfer();

contract Ledger is ReentrancyGuard {
    mapping(bytes32 => uint256) private UTXO;
    mapping(bytes32 => bool) private commits;

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

    /**
     * @dev do not use it for utxo root generation for deposit or transfer
     */
    function getUtxoRoot(bytes32 proofSecret, bytes32 spendSecret)
        private
        view
        returns (bytes32 utxoRoot)
    {
        utxoRoot = LedgerLib.efficientHash(proofSecret, keccak256(abi.encode(spendSecret)));
        if (balanceOf(utxoRoot) == 0) {
            revert UTXONotFound(utxoRoot);
        }
    }

    function withdraw(bytes32 proofSecret, bytes32 spendSecret, address payable recepient)
        external
        nonReentrant
        returns (bool)
    {
        bytes32 utxoRoot = getUtxoRoot(proofSecret, spendSecret);
        (bool sentStatus,) = recepient.call{value: UTXO[utxoRoot]}("");
        if (!sentStatus) {
            revert FailedTransaction();
        }
        delete UTXO[utxoRoot];
        return sentStatus;
    }

    function commitTransfer(bytes32 commitHash) external returns (bool) {
        commits[commitHash] = true;
        return true;
    }

    function transfer(
        LedgerLib.OutputUTXO[] calldata ouputs,
        bytes32 proofSecret,
        bytes32 spendSecret
    ) external nonReentrant returns (bool) {
        bytes32 utxoRoot = getUtxoRoot(proofSecret, spendSecret);
        bytes32 commitHash = LedgerLib.createCommitHash(ouputs, utxoRoot);
        if (!commits[commitHash]) {
            revert CommitmentNotFound();
        }
        uint256 utxoBalance = balanceOf(utxoRoot);
        uint256 spendingBalance;
        for (uint256 i = 0; i < ouputs.length; i++) {
            spendingBalance += ouputs[i].value;
        }
        if (utxoBalance != spendingBalance) {
            revert InvalidTransfer();
        }
        for (uint256 i = 0; i < ouputs.length; i++) {
            UTXO[ouputs[i].utxoRoot] = ouputs[i].value;
        }
        delete UTXO[utxoRoot];
        return true;
    }
}
