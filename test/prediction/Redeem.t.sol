// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract RedeemTest is PredictionSetup {
    /*
     * アリスとボブがそれぞれ100ファントークンをベット
     */
    function setUp() public override {
        super.setUp();

        // aliceがベット
        vm.startPrank(alice);

        mockFanToken.mint(alice, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        predictionMarket.bet(marketId1, 1, 1e18, type(uint256).max);
        vm.stopPrank();

        // bobがベット
        vm.startPrank(bob);

        mockFanToken.mint(bob, 100 * 1e18);
        mockFanToken.approve(address(predictionMarket), 100 * 1e18);

        predictionMarket.bet(marketId1, 0, 1e18, type(uint256).max);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
    }

    // aliceとbobが期限切れになった予測市場を解約する
    function testRedeem() public {
        assertEq(mockFanToken.balanceOf(bob), 50 * 1e18);

        vm.warp(block.timestamp + 14 days);

        vm.startPrank(bob);
        predictionMarket.redeem(marketId1);
        vm.stopPrank();

        // bobのファントークンが戻っていることを確認
        assertEq(mockFanToken.balanceOf(bob), 100 * 1e18);

        vm.startPrank(alice);
        predictionMarket.redeem(marketId1);
        vm.stopPrank();

        // aliceのファントークンが戻っていることを確認
        assertEq(mockFanToken.balanceOf(alice), 100 * 1e18);
    }

    // 期限切れになっていない予測市場を解約しようとしたら、リバートする
    function testCannotRedeem_NotTimedOut() public {
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.MarketNotTimedOut.selector));
        predictionMarket.redeem(marketId1);
        vm.stopPrank();
    }

    // 市場がすでに閉じている場合は解約できない
    function testCannotRedeem_NotActive() public {
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(owner);
        predictionMarket.closeMarket(marketId1, 1);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.MarketNotActive.selector));
        predictionMarket.redeem(marketId1);
        vm.stopPrank();
    }
}
