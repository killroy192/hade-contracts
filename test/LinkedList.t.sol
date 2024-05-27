// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console

import "@std/Test.sol";

import {ListIsEmpty, LinkedList, LinkedListLibrary} from "src/libs/LinkedList.sol";

contract LinkedListTest is Test {
    using LinkedListLibrary for LinkedList;

    LinkedList private list;

    address private immutable ALICE = makeAddr("alice");
    address private immutable BOB = makeAddr("bob");
    address private immutable DAN = makeAddr("dan");
    address private immutable CLAUS = makeAddr("claus");

    function fill() private {
        list.push(ALICE);
        list.push(BOB);
        list.push(DAN);
        list.push(CLAUS);
    }

    // function testFuzz_push(uint8 len) external {
    //     vm.assume(len < 10);
    //     for (uint8 i = 0; i < len; i++) {
    //         list.push(makeAddr(string(abi.encode(i))));
    //     }
    //     assertEq(list.length, len);
    //     if (list.length > 1) {
    //         assertNotEq(list.head, list.tail);
    //     }
    //     if (list.length == 1) {
    //         assertEq(list.head, list.tail);
    //     }
    // }

    // function test_push() external {
    //     list.push(ALICE);
    //     list.push(BOB);
    //     assertEq(list.length, 2);
    //     assertEq(list.head, ALICE);
    //     assertEq(list.next[ALICE], BOB);
    //     assertEq(list.prev[ALICE], address(0));
    //     assertEq(list.tail, BOB);
    //     assertEq(list.next[BOB], address(0));
    //     assertEq(list.prev[BOB], ALICE);
    // }

    // function test_position() external {
    //     fill();
    //     assertEq(list.position(ALICE), 0);
    //     assertEq(list.position(BOB), 1);
    //     assertEq(list.position(DAN), 2);
    //     assertEq(list.position(CLAUS), 3);
    // }

    function test_toList() external {
        fill();
        address[] memory arr = list.toList(ALICE, 2);
        assertEq(arr.length, 2);
        assertEq(arr[0], BOB);
        assertEq(arr[1], DAN);
    }

    // function testFuzz_shift(uint8 rounds) external {
    //     vm.assume(rounds < 5);
    //     fill();
    //     for (uint8 i = 0; i < rounds; i++) {
    //         if (i > 3) {
    //             vm.expectRevert(abi.encodeWithSelector(ListIsEmpty.selector));
    //         }
    //         list.shift();
    //     }
    //     if (rounds > 0) {
    //         assertLe(list.length, 4);
    //     }
    // }

    // function test_shift() external {
    //     fill();
    //     address firstShift = list.shift();
    //     address secondShift = list.shift();
    //     assertEq(firstShift, ALICE);
    //     assertEq(secondShift, BOB);
    //     assertEq(list.length, 2);
    // }

    // function test_reorg_head() external {
    //     fill();
    //     list.reorg(ALICE);
    //     assertEq(list.head, ALICE);
    //     assertEq(list.next[ALICE], BOB);
    //     assertEq(list.prev[BOB], ALICE);

    //     assertEq(list.position(ALICE), 0);
    //     assertEq(list.position(BOB), 1);
    //     assertEq(list.position(DAN), 2);
    //     assertEq(list.position(CLAUS), 3);
    // }

    // function test_reorg_middle() external {
    //     fill();
    //     list.reorg(BOB);
    //     assertEq(list.head, BOB);
    //     assertEq(list.next[BOB], ALICE);
    //     assertEq(list.prev[BOB], address(0));
    //     assertEq(list.next[ALICE], DAN);
    //     assertEq(list.prev[ALICE], BOB);

    //     assertEq(list.position(ALICE), 1);
    //     assertEq(list.position(BOB), 0);
    //     assertEq(list.position(DAN), 2);
    //     assertEq(list.position(CLAUS), 3);
    // }

    // function test_reorg_tail() external {
    //     fill();
    //     list.reorg(CLAUS);
    //     assertEq(list.head, CLAUS);
    //     assertEq(list.next[CLAUS], ALICE);
    //     assertEq(list.prev[ALICE], CLAUS);
    //     assertEq(list.tail, DAN);
    //     assertEq(list.next[DAN], address(0));
    //     assertEq(list.prev[DAN], BOB);

    //     assertEq(list.position(ALICE), 1);
    //     assertEq(list.position(BOB), 2);
    //     assertEq(list.position(DAN), 3);
    //     assertEq(list.position(CLAUS), 0);
    // }
}
