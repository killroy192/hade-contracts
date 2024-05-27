// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IOracle} from "src/oracle/Oracle.types.sol";

contract MockOracle is IOracle {
    using Math for uint256;

    uint256 private _price = 1000;

    function decimals() public pure returns (uint8) {
        return 16;
    }

    function getExposurePrice() external view returns (uint256) {
        return _price * 10 ** decimals();
    }

    function getHedgePrice() external view returns (uint256) {
        return uint256(1).mulDiv(decimals(), _price);
    }

    function setPrice(uint256 exposurePrice) external {
        _price = exposurePrice;
    }
}
