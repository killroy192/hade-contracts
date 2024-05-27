// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error ListIsEmpty();
error AdressAlreadyExist();
error AdressNotExist();

struct LinkedList {
    mapping(address => address) next;
    mapping(address => address) prev;
    address tail;
    address head;
    uint128 length;
}

library LinkedListLibrary {
    modifier notEmpty(LinkedList storage list) {
        if (list.length == 0) {
            revert ListIsEmpty();
        }
        _;
    }

    modifier notExist(LinkedList storage list, address value) {
        if (isExist(list, value)) {
            revert AdressAlreadyExist();
        }
        _;
    }

    modifier exist(LinkedList storage list, address value) {
        if (!isExist(list, value)) {
            revert AdressNotExist();
        }
        _;
    }

    function isExist(LinkedList storage list, address value) public view returns (bool) {
        return list.tail == value || list.next[value] != address(0);
    }

    function isEmpty(LinkedList storage list) public view returns (bool) {
        return list.length == 0;
    }

    function push(LinkedList storage list, address value) external notExist(list, value) {
        _push(list, value);
    }

    function _push(LinkedList storage list, address value) private {
        if (!isEmpty(list)) {
            list.next[list.tail] = value;
            list.prev[value] = list.tail;
        } else {
            list.head = value;
        }
        list.tail = value;
        list.length += 1;
    }

    function remove(LinkedList storage list, address value) external exist(list, value) {
        address next_value = list.next[value];
        address prev_value = list.prev[value];
        list.prev[next_value] = prev_value;
        list.next[prev_value] = next_value;
        if (value == list.head) {
            list.head = next_value;
        }
        if (value == list.tail) {
            list.tail = prev_value;
        }
        delete list.next[value];
        delete list.prev[value];
        list.length -= 1;
    }

    function toList(LinkedList storage list, address value, uint256 amount)
        external
        view
        returns (address[] memory)
    {
        address[] memory result = new address[](amount);

        uint256 i = 0;
        address item = value == address(0) ? list.head : list.next[value];

        while (i <= amount - 1 && item != address(0)) {
            result[i] = item;
            item = list.next[item];
            i += 1;
        }
        return result;
    }
}
