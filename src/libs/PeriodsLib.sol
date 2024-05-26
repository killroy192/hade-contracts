// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error WrongMarketPeriod(uint32 period);

library PeriodsLib {
    uint32 public constant REDEEM_PERIOD = 7200; // ~ 1 day
    uint32 public constant WEEK_PERIOD = 50400;
    uint32 public constant MONTH_PERIOD = 216000;
    uint32 public constant HALF_YEAR = 1296000;
    uint32 public constant YEAR = 2628000;

    function isPeriodValid(uint32 period) external pure returns (bool) {
        // solhint-disable max-line-length
        return
            period == WEEK_PERIOD || period == MONTH_PERIOD || period == HALF_YEAR || period == YEAR;
    }

    function periodName(uint32 period) external pure returns (string memory) {
        if (period == WEEK_PERIOD) {
            return "weekly";
        }
        if (period == MONTH_PERIOD) {
            return "monthly";
        }
        if (period == HALF_YEAR) {
            return "half_year";
        }
        return "yearly";
    }
}
