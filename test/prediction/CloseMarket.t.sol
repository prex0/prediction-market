// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract CloseMarketTest is PredictionSetup {
    function setUp() public override {
        super.setUp();

        vm.startPrank(alice);

        mockFanToken.mint(alice, 1000 * 1e18);
        mockFanToken.approve(address(predictionMarket), 1000 * 1e18);

        predictionMarket.bet(marketId1, 1, 1e18);
        vm.stopPrank();
    }

    function testCloseMarket() public {
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);

        predictionMarket.closeMarket(marketId1, 1);

        vm.stopPrank();
    }

    function testCannotCloseMarket_NotExpired() public {
        vm.startPrank(owner);

        vm.expectRevert(SimplePredictionMarket.MarketNotExpired.selector);
        predictionMarket.closeMarket(marketId1, 0);

        vm.stopPrank();
    }

    function testCannotCloseMarket_NotCreator() public {
        vm.startPrank(alice);

        vm.expectRevert(SimplePredictionMarket.OnlyCreator.selector);
        predictionMarket.closeMarket(marketId1, 0);
    }

    function testCannotCloseMarket_InvalidInput() public {
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);

        vm.expectRevert(SimplePredictionMarket.InvalidInput.selector);
        predictionMarket.closeMarket(marketId1, 2);

        vm.stopPrank();
    }
}
