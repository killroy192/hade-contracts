// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-global-import
// solhint-disable no-console
import "@std/Test.sol";

import {LinkedList, LinkedListLibrary} from "src/registry/libs/LinkedList.sol";

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

    function testFuzz_push(uint8 len) external {
        vm.assume(len < 10);
        for (uint8 i = 0; i < len; i++) {
            list.push(makeAddr(string(abi.encode(i))));
        }
        assertEq(list.length, len);
        if (list.length > 1) {
            assertNotEq(list.head, list.tail);
        }
        if (list.length == 1) {
            assertEq(list.head, list.tail);
        }
    }

    function test_push() external {
        list.push(ALICE);
        list.push(BOB);
        assertEq(list.length, 2);
        assertEq(list.head, ALICE);
        assertEq(list.next[ALICE], BOB);
        assertEq(list.prev[ALICE], address(0));
        assertEq(list.tail, BOB);
        assertEq(list.next[BOB], address(0));
        assertEq(list.prev[BOB], ALICE);
    }

    function test_isEmpty() external {
        assertEq(list.isEmpty(), true);
        list.push(ALICE);
        assertEq(list.isEmpty(), false);
    }

    function test_isExist() external {
        assertEq(list.isExist(ALICE), false);
        list.push(ALICE);
        assertEq(list.isExist(ALICE), true);
    }

    function test_toList() external {
        fill();
        address[] memory arr = list.toList(ALICE, 2);
        assertEq(arr.length, 2);
        assertEq(arr[0], BOB);
        assertEq(arr[1], DAN);
    }

    function test_remove() external {
        fill();
        list.remove(DAN);
        assertEq(list.length, 3);
        assertEq(list.isExist(DAN), false);
        assertEq(list.head, ALICE);
        assertEq(list.next[ALICE], BOB);
        assertEq(list.next[BOB], CLAUS);
        assertEq(list.tail, CLAUS);
    }
}
