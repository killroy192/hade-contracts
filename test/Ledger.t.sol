// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {Ledger} from "src/Ledger.sol";
import {LedgerLib} from "src/LedgerLib.sol";
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
        utxoRoot = LedgerLib.efficientHash(PROOF_SECRET, spend_secret_h);
    }

    function deposit(uint8 amount) private returns (uint256) {
        uint256 parsedAmount = TestUtils.to256dec(amount, 7);
        ledger.deposit{value: parsedAmount}(utxoRoot);
        return parsedAmount;
    }

    function testFuzz_deposit(uint8 amount) external {
        vm.assume(amount > 0);
        uint256 parsedAmount = deposit(amount);
        assertEq(ledger.balanceOf(utxoRoot), parsedAmount);
    }

    function testFuzz_withdraw(uint8 amount) external {
        vm.assume(amount > 0);
        uint256 parsedAmount = deposit(amount);
        ledger.withdraw(PROOF_SECRET, SPEND_SECRET, payable(ALICE));
        assertEq(ledger.balanceOf(utxoRoot), 0);
        assertEq(ALICE.balance, parsedAmount);
    }

    function test_transfer() external {
        uint256 parsedAmount = deposit(1);
        bytes32 newUtxoRoot = bytes32("new_utxoRoot");
        LedgerLib.OutputUTXO[] memory outputUtxos = new LedgerLib.OutputUTXO[](1);
        outputUtxos[0] = LedgerLib.OutputUTXO({value: parsedAmount, utxoRoot: newUtxoRoot});
        ledger.commitTransfer(LedgerLib.createCommitHash(outputUtxos, utxoRoot));
        ledger.transfer(outputUtxos, PROOF_SECRET, SPEND_SECRET);
        assertEq(ledger.balanceOf(newUtxoRoot), parsedAmount);
    }
}
