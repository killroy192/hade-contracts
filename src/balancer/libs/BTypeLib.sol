// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {BTypes} from "../Balancer.types.sol";

library BTypeLib {
    function toString(BTypes rebType) external pure returns (string memory) {
        if (rebType == BTypes.Tick) {
            return "tick";
        }
        if (rebType == BTypes.PeriodTick) {
            return "periodTick";
        }
        return "upOnlyTick";
    }
}
