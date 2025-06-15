// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract SlippageTest is PredictionSetup {
    function setUp() public override {
        super.setUp();
    }

    function testBet_SlippageProtection() public {
        vm.startPrank(alice);

        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        uint256 expectedCost = predictionMarket.getPurchaseCost(marketId1, 1, 1e18);
        uint256 actualAmount = AmountMathLib.ceil(expectedCost * 100 * 1e18 / 1e18, 1e18);

        // This should succeed - maxCost is exactly what we expect
        predictionMarket.bet(marketId1, 1, 1e18, actualAmount);

        vm.stopPrank();
    }

    function testBet_SlippageExceeded() public {
        vm.startPrank(alice);

        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        // This should fail - maxCost is too low
        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.SlippageExceeded.selector));
        predictionMarket.bet(marketId1, 1, 1e18, 1); // maxCost = 1 wei (too low)

        vm.stopPrank();
    }
}
