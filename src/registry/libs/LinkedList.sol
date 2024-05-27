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
            // tail -> value
            list.next[list.tail] = value;
            // tail <- value
            list.prev[value] = list.tail;
        } else {
            list.head = value;
        }
        list.tail = value;
        list.length += 1;
    }

    function shift(LinkedList storage list) external notEmpty(list) returns (address) {
        address value = list.head;
        address next_value = list.next[value];
        list.head = next_value;
        if (value == list.tail) {
            delete list.tail;
        }
        delete list.prev[next_value];
        delete list.next[value];
        list.length -= 1;
        return value;
    }

    function reorg(LinkedList storage list, address value) external {
        if (isExist(list, value) && value != list.head) {
            _omit(list, value);
            address head_value = list.head;
            list.head = value;
            list.prev[head_value] = value;
            list.next[value] = head_value;
            list.prev[value] = address(0);
        } else {
            _push(list, value);
        }
    }

    function _omit(LinkedList storage list, address value) private {
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
    }

    function remove(LinkedList storage list, address value) external exist(list, value) {
        _omit(list, value);
        delete list.next[value];
        delete list.prev[value];
        list.length -= 1;
    }

    /**
     * @dev use only for test porposes
     * todo migrate to dev utils
     */
    function position(LinkedList storage list, address value)
        external
        view
        exist(list, value)
        returns (uint256)
    {
        if (list.head == value) {
            return 0;
        }

        if (list.tail == value) {
            return list.length - 1;
        }

        address candidate = list.next[list.head];
        uint256 order = 1;

        while (order < list.length && candidate != value) {
            candidate = list.next[candidate];
            order += 1;
        }

        return order;
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
