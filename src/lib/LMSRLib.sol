// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {wadLn, wadExp} from "../../lib/solmate/src/utils/SignedWadMath.sol";

library LMSRLib {
    uint256 constant SCALE = 1e18;

    // Computes LMSR cost function: C = b * log(exp(q_yes / b) + exp(q_no / b))
    function calcCost(uint256[] memory quantity, uint256 b) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < quantity.length; i++) {
            total += exp(quantity[i] * SCALE / b);
        }
        return b * log(total) / SCALE;
    }

    function calcSubsidy(uint256 b) internal pure returns (uint256) {
        return b * log(2 * SCALE) / SCALE;
    }

    // Calculates marginal price for Yes
    function priceYes(uint256 qYes, uint256 qNo, uint256 b) internal pure returns (uint256) {
        uint256 expYes = exp(qYes * SCALE / b);
        uint256 expNo = exp(qNo * SCALE / b);
        return (expYes * SCALE) / (expYes + expNo);
    }

    // Calculates marginal price for No
    function priceNo(uint256 qYes, uint256 qNo, uint256 b) internal pure returns (uint256) {
        uint256 expYes = exp(qYes * SCALE / b);
        uint256 expNo = exp(qNo * SCALE / b);
        return (expNo * SCALE) / (expYes + expNo);
    }

    // Approximate exp using Taylor series (good enough for small range)
    function exp(uint256 x) internal pure returns (uint256 result) {
        return uint256(wadExp(int256(x)));
    }

    // Approximate natural log using log base 2 and change-of-base formula
    function log(uint256 x) internal pure returns (uint256) {
        return uint256(wadLn(int256(x)));
    }
}
