// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LMSRLib} from "../../src/lib/LMSRLib.sol";
import {AmountMathLib} from "../../src/lib/AmountMathLib.sol";

contract WrappedLMSRLib {
    uint256 yy = 0;
    uint256 nn = 0;
    uint256 b = 16000 * 1e18;

    function calcCost(uint256 qYes, uint256 qNo) external view returns (uint256) {
        return LMSRLib.calcCost(qYes, qNo, b);
    }

    function calcSubsidy() external view returns (uint256) {
        return LMSRLib.calcSubsidy(b);
    }

    function calcRequiredCost(uint256 y, uint256 n) external returns (uint256) {
        uint256 cost = LMSRLib.calcCost(yy + y, nn + n, b) - LMSRLib.calcCost(yy, nn, b);
        yy += y;
        nn += n;
        return AmountMathLib.ceil(cost, 1e18);
    }
}

contract LMSRLibTest is Test {
    WrappedLMSRLib public lmsrLib;

    function setUp() public {
        lmsrLib = new WrappedLMSRLib();
    }

    function test_calcCost() public view {
        assertEq(lmsrLib.calcCost(1000 * 1e18, 1000 * 1e18), 12090354888959124928000);
    }

    function test_calcSubsidy() public view {
        // 11090
        assertEq(lmsrLib.calcSubsidy(), 11090354888959124944000);
    }

    function test_calcRequiredCost() public {
        assertEq(lmsrLib.calcRequiredCost(1000 * 1e18, 0), 508000000000000000000);
        assertEq(lmsrLib.calcRequiredCost(0, 1000 * 1e18), 493000000000000000000);
        assertEq(lmsrLib.calcRequiredCost(2000 * 1e18, 0), 1032000000000000000000);
        assertEq(lmsrLib.calcRequiredCost(0, 1000 * 1e18), 477000000000000000000);
        assertEq(lmsrLib.calcRequiredCost(0, 1000 * 1e18), 493000000000000000000);

        assertEq(lmsrLib.calcRequiredCost(1000 * 1e18, 0), 508000000000000000000);
        assertEq(lmsrLib.calcRequiredCost(0, 1000 * 1e18), 493000000000000000000);
    }
}
