// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract Scenario2Test is PredictionSetup {
    /*
     * オーナーは100ファントークンを基準に設定し、200トークンをデポジットした。
     * アリスは1に30ベットし、ボブは0に20ベット
     * アリスが選択した1を正解として、市場を閉じる
     */
    function setUp() public override {
        super.setUp();

        // aliceがベット
        vm.startPrank(alice);

        mockFanToken.mint(alice, 20000 * 1e18);
        mockFanToken.approve(address(predictionMarket), 20000 * 1e18);

        predictionMarket.bet(marketId1, 1, 30 * 1e18, type(uint256).max);

        // 2120 cost / 30 = 70.666666666666666666666666666666666666
        //assertEq(mockFanToken.balanceOf(alice), 7880 * 1e18);

        vm.stopPrank();

        // bobがベット
        vm.startPrank(bob);

        mockFanToken.mint(bob, 2000 * 1e18);
        mockFanToken.approve(address(predictionMarket), 2000 * 1e18);

        predictionMarket.bet(marketId1, 0, 30 * 1e18, type(uint256).max);

        // 881 cost / 30 = 29.366666666666666666666666666666666666
        assertEq(mockFanToken.balanceOf(bob), 1119 * 1e18);

        vm.stopPrank();

        assertEq(predictionMarket.getPurchaseCost(marketId1, 1, 30 * 1e18), 21192446032730499392);
        // aliceがベット
        vm.startPrank(alice);

        predictionMarket.bet(marketId1, 1, 100 * 1e18, type(uint256).max);

        // 2120 cost / 30 = 70.666666666666666666666666666666666666
        assertEq(mockFanToken.balanceOf(alice), 8985 * 1e18);

        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);

        predictionMarket.closeMarket(marketId1, 1);

        // オーナーは149ファントークンを引き出す
        assertEq(mockFanToken.balanceOf(address(owner)), 8896000000000000000000);

        vm.stopPrank();
    }

    // アリスが報酬を請求する
    function testClaimReward() public {
        assertEq(mockFanToken.balanceOf(address(predictionMarket)), 13000000000000000000000);

        // アリスが報酬を請求する
        vm.startPrank(alice);

        predictionMarket.claimReward(marketId1);

        vm.stopPrank();

        // アプリは158で3ベット購入し、最終的に300を獲得
        assertEq(mockFanToken.balanceOf(alice), 21985 * 1e18);
        assertEq(mockFanToken.balanceOf(address(predictionMarket)), 0);
    }
}
