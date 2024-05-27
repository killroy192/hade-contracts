// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {RTypes} from "../Rebalancer.types.sol";

library RTypeLib {
    function toString(RTypes rebType) external pure returns (string memory) {
        if (rebType == RTypes.Tick) {
            return "tick";
        }
        if (rebType == RTypes.PeriodTick) {
            return "periodTick";
        }
        return "upOnlyTick";
    }
}
