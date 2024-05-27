// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IOracle} from "src/oracle/Oracle.types.sol";

contract MockOracle is IOracle {
    using Math for uint256;

    uint256 private _price = 1000;

    function getExposurePrice(uint8 dec) public view returns (uint256) {
        return _price * 10 ** dec;
    }

    function getHedgePrice(uint8 dec) external view returns (uint256) {
        return uint256(1 * 10 ** dec).mulDiv(10 ** dec, getExposurePrice(dec));
    }

    function setPrice(uint256 exposurePrice) external {
        _price = exposurePrice;
    }
}
