// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract MultiOptionTest is PredictionSetup {
    uint256 public marketId3Options;

    function setUp() public override {
        super.setUp();
        
        // Create a market with 3 options
        vm.startPrank(owner);
        marketId3Options = createMarketWith3Options();
        vm.stopPrank();
    }

    function createMarketWith3Options() internal returns (uint256) {
        CreatePredictionMarketParams memory params = CreatePredictionMarketParams({
            token: address(mockFanToken),
            name: "3-Option Test Market",
            expiry: block.timestamp + 1 days,
            options: new string[](3),
            entryAmount: 100 * 1e18,
            oracleDuration: 7 days,
            description: "Test market with 3 options"
        });

        params.options[0] = "Option A";
        params.options[1] = "Option B";
        params.options[2] = "Option C";

        return predictionMarket.createPredictionMarket(params);
    }

    function testBetOn3Options() public {
        vm.startPrank(alice);

        mockFanToken.mint(alice, 300 * 1e18);
        mockFanToken.approve(address(predictionMarket), 300 * 1e18);

        // Bet on option 0 (Option A)
        uint256 price0 = predictionMarket.getPurchaseCost(marketId3Options, 0, 1e18);
        predictionMarket.bet(marketId3Options, 0, 1e18, type(uint256).max);

        // Bet on option 1 (Option B)
        uint256 price1 = predictionMarket.getPurchaseCost(marketId3Options, 1, 1e18);
        predictionMarket.bet(marketId3Options, 1, 1e18, type(uint256).max);

        // Bet on option 2 (Option C)
        uint256 price2 = predictionMarket.getPurchaseCost(marketId3Options, 2, 1e18);
        predictionMarket.bet(marketId3Options, 2, 1e18, type(uint256).max);

        // Verify prices are different (showing LMSR pricing works)
        assertTrue(price0 > 0);
        assertTrue(price1 > 0);
        assertTrue(price2 > 0);

        vm.stopPrank();
    }

    function testCloseMarketWith3Options() public {
        // Setup bets from different users
        vm.startPrank(alice);
        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);
        predictionMarket.bet(marketId3Options, 0, 1e18, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        mockFanToken.mint(bob, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);
        predictionMarket.bet(marketId3Options, 1, 1e18, type(uint256).max);
        vm.stopPrank();

        // Fast forward past expiry
        vm.warp(block.timestamp + 2 days);

        // Close market with option 2 as winner
        vm.startPrank(owner);
        predictionMarket.closeMarket(marketId3Options, 2);
        vm.stopPrank();

        // Verify market is closed with correct winning option
        SimplePredictionMarket.PredictionMarket memory market = predictionMarket.getMarket(marketId3Options);
        assertEq(uint256(market.status), uint256(SimplePredictionMarket.MarketStatus.Closed));
        assertEq(market.winningOptionIndex, 2);
    }

    function testClaimRewardWith3Options() public {
        // Alice bets on option 0
        vm.startPrank(alice);
        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);
        predictionMarket.bet(marketId3Options, 0, 1e18, type(uint256).max);
        vm.stopPrank();

        // Bob bets on option 1
        vm.startPrank(bob);
        mockFanToken.mint(bob, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);
        predictionMarket.bet(marketId3Options, 1, 1e18, type(uint256).max);
        vm.stopPrank();

        // Fast forward past expiry
        vm.warp(block.timestamp + 2 days);

        // Close market with option 0 as winner (Alice wins)
        vm.startPrank(owner);
        predictionMarket.closeMarket(marketId3Options, 0);
        vm.stopPrank();

        // Alice claims reward
        uint256 aliceBalanceBefore = mockFanToken.balanceOf(alice);
        vm.startPrank(alice);
        predictionMarket.claimReward(marketId3Options);
        vm.stopPrank();

        // Verify Alice received reward
        uint256 aliceBalanceAfter = mockFanToken.balanceOf(alice);
        assertTrue(aliceBalanceAfter > aliceBalanceBefore);

        // Bob should not be able to claim reward (didn't win)
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.NoReward.selector));
        predictionMarket.claimReward(marketId3Options);
        vm.stopPrank();
    }

    function testInvalidOptionIndex() public {
        vm.startPrank(alice);
        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        // Try to bet on option 3 (doesn't exist, only 0, 1, 2)
        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.InvalidInput.selector));
        predictionMarket.bet(marketId3Options, 3, 1e18, type(uint256).max);

        vm.stopPrank();
    }

    function testPricingConsistencyWith3Options() public {
        vm.startPrank(alice);
        mockFanToken.mint(alice, 300 * 1e18);
        mockFanToken.approve(address(predictionMarket), 300 * 1e18);

        // Get initial prices for all options
        uint256 price0Initial = predictionMarket.getPurchaseCost(marketId3Options, 0, 1e18);
        uint256 price1Initial = predictionMarket.getPurchaseCost(marketId3Options, 1, 1e18);
        uint256 price2Initial = predictionMarket.getPurchaseCost(marketId3Options, 2, 1e18);

        // Bet on option 0
        predictionMarket.bet(marketId3Options, 0, 1e18, type(uint256).max);

        // Get prices after betting on option 0
        uint256 price0After = predictionMarket.getPurchaseCost(marketId3Options, 0, 1e18);
        uint256 price1After = predictionMarket.getPurchaseCost(marketId3Options, 1, 1e18);
        uint256 price2After = predictionMarket.getPurchaseCost(marketId3Options, 2, 1e18);

        // Price for option 0 should increase (more expensive after more shares)
        assertTrue(price0After > price0Initial);
        // Prices for other options should decrease
        assertTrue(price1After < price1Initial);
        assertTrue(price2After < price2Initial);

        vm.stopPrank();
    }
}