// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AmountMathLib {
    function ceilCredit(uint256 value) internal pure returns (uint256) {
        return ceil(value, 1e6);
    }

    function ceil(uint256 value, uint256 precision) internal pure returns (uint256) {
        return precision * ((value + precision - 1) / precision);
    }

    function floor(uint256 value, uint256 precision) internal pure returns (uint256) {
        return precision * (value / precision);
    }
}
