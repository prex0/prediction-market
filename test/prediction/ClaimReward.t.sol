// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract ClaimRewardTest is PredictionSetup {
    /*
     * オーナーは100ファントークンを基準に設定し、200トークンをデポジットした。
     * アリスは1に2ベットし、ボブは0に2ベット
     * アリスが選択した1を正解として、市場を閉じる
     */
    function setUp() public override {
        super.setUp();

        // aliceがベット
        vm.startPrank(alice);

        mockFanToken.mint(alice, 200 * 1e18);
        mockFanToken.approve(address(predictionMarket), 200 * 1e18);

        predictionMarket.bet(marketId1, 1, 2 * 1e18);

        // 104 cost
        assertEq(mockFanToken.balanceOf(alice), 96 * 1e18);

        vm.stopPrank();

        // bobがベット
        vm.startPrank(bob);

        mockFanToken.mint(bob, 200 * 1e18);
        mockFanToken.approve(address(predictionMarket), 200 * 1e18);

        predictionMarket.bet(marketId1, 0, 2 * 1e18);

        // 97 cost
        assertEq(mockFanToken.balanceOf(bob), 103 * 1e18);

        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);

        predictionMarket.closeMarket(marketId1, 1);

        // オーナーは200ファントークンを引き出す
        assertEq(mockFanToken.balanceOf(address(owner)), 10001 * 1e18);

        vm.stopPrank();
    }

    // アリスが報酬を請求する
    function testClaimReward() public {
        assertEq(mockFanToken.balanceOf(address(predictionMarket)), 200000000000000000000);

        // アリスが報酬を請求する
        vm.startPrank(alice);

        predictionMarket.claimReward(marketId1);

        vm.stopPrank();

        // アプリは104で2ベット購入し、最終的に200を獲得
        assertEq(mockFanToken.balanceOf(alice), 296 * 1e18);
        assertEq(mockFanToken.balanceOf(address(predictionMarket)), 0);
    }

    // 報酬が0の場合はリバートする
    function testCannotClaimReward_NoReward() public {
        vm.startPrank(bob);

        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.NoReward.selector));
        predictionMarket.claimReward(marketId1);

        vm.stopPrank();

        assertEq(mockFanToken.balanceOf(bob), 103 * 1e18);
    }
}
