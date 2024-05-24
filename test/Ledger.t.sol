// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {Ledger} from "src/Ledger.sol";
import {TestUtils} from "./TestUtils.sol";

contract LedgerTest is Test {
    Ledger private ledger;
    bytes32 private spend_secret_h;
    bytes32 private utxoRoot;

    address private immutable ALICE = makeAddr("alice");
    bytes32 private immutable PROOF_SECRET = bytes32("PROOF_SECRET");
    bytes32 private immutable SPEND_SECRET = bytes32("SPEND_SECRET");

    function setUp() public {
        ledger = new Ledger();
        spend_secret_h = keccak256(abi.encode(SPEND_SECRET));
        utxoRoot = TestUtils.hashPair(spend_secret_h, PROOF_SECRET);
    }

    function testFuzz_deposit(uint8 amount) external {
        vm.assume(amount > 0);
        uint256 deposit = TestUtils.to256dec(amount, 7);
        ledger.deposit{value: deposit}(utxoRoot);
        assertEq(ledger.balanceOf(utxoRoot), deposit);
    }

    function testFuzz_withdraw(uint8 amount) external {
        vm.assume(amount > 0);
        uint256 deposit = TestUtils.to256dec(amount, 7);
        ledger.deposit{value: deposit}(utxoRoot);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = PROOF_SECRET;
        ledger.withdraw(proof, utxoRoot, SPEND_SECRET, payable(ALICE));
        assertEq(ledger.balanceOf(utxoRoot), 0);
        assertEq(ALICE.balance, deposit);
    }
}
