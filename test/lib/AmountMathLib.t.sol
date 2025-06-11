// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AmountMathLib} from "../../src/lib/AmountMathLib.sol";

contract WrappedAmountMathLib {
    function ceilCredit(uint256 value) external pure returns (uint256) {
        return AmountMathLib.ceilCredit(value);
    }
}

contract AmountMathTest is Test {
    WrappedAmountMathLib public amountMathLib;

    function setUp() public {
        amountMathLib = new WrappedAmountMathLib();
    }

    function test_ceilCredit() public view {
        assertEq(amountMathLib.ceilCredit(1e6), 1e6);
        assertEq(amountMathLib.ceilCredit(1e6 + 1), 2e6);
        assertEq(amountMathLib.ceilCredit(1e6 - 1), 1e6);
        assertEq(amountMathLib.ceilCredit(1e6 + 1e6 - 1), 2e6);
        assertEq(amountMathLib.ceilCredit(1), 1e6);
        assertEq(amountMathLib.ceilCredit(1e8), 1e8);
        assertEq(amountMathLib.ceilCredit(1e8 + 1), 1e8 + 1e6);
    }
}
