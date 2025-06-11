// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract BetTest is PredictionSetup {
    function setUp() public override {
        super.setUp();
    }

    function testBet() public {
        vm.startPrank(alice);

        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        uint256 price1 = predictionMarket.getPurchaseCost(marketId1, 1, 1e18);
        assertEq(price1, 507811228765283568);

        predictionMarket.bet(marketId1, 1, 1e18);

        assertEq(mockFanToken.balanceOf(alice), 49 * 1e18);

        vm.stopPrank();
    }

    // オプションが存在しない場合はエラー
    function testBet_InvalidInput() public {
        vm.startPrank(alice);

        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.InvalidInput.selector));
        predictionMarket.bet(marketId1, 5, 1e18);

        vm.stopPrank();
    }
}
