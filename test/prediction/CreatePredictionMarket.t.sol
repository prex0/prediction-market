// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/SimplePredictionMarket.sol";
import "./Setup.t.sol";

contract CreatePredictionMarketTest is PredictionSetup {
    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        mockCredit.mint(owner, 10000 * 1e6);
        mockCredit.approve(address(predictionMarket), 10000 * 1e6);

        mockFanToken.mint(owner, 10000 * 1e18);
        mockFanToken.approve(address(predictionMarket), 10000 * 1e18);
        vm.stopPrank();
    }

    function testCreatePredictionMarket() public {
        vm.startPrank(owner);
        CreatePredictionMarketParams memory params = CreatePredictionMarketParams({
            token: address(mockFanToken),
            name: "Test Market",
            expiry: block.timestamp + 1 days,
            options: new string[](2),
            entryAmount: 100 * 1e18,
            oracleDuration: 7 days,
            description: "Test Description"
        });

        params.options[0] = "Option 1";
        params.options[1] = "Option 2";

        uint256 marketId = predictionMarket.createPredictionMarket(params);

        SimplePredictionMarket.PredictionMarket memory market = predictionMarket.getMarket(marketId);

        assertEq(market.creator, owner);
        assertEq(market.marketName, "Test Market");
        assertEq(market.expiry, params.expiry);
        assertEq(market.entryAmount, params.entryAmount);
        assertEq(market.optionLabels.length, params.options.length);
        assertEq(market.optionLabels[0], params.options[0]);
        assertEq(market.optionLabels[1], params.options[1]);
        assertTrue(market.status == SimplePredictionMarket.MarketStatus.Active);
        vm.stopPrank();
    }

    // 10ファントークン未満の場合はエラー
    function testCreatePredictionMarket_InvalidInput_EntryAmountTooLow() public {
        vm.startPrank(owner);
        CreatePredictionMarketParams memory params = CreatePredictionMarketParams({
            token: address(mockFanToken),
            name: "Test Market",
            expiry: block.timestamp + 1 days,
            options: new string[](2),
            entryAmount: 9 * 1e18,
            oracleDuration: 7 days,
            description: "Test Description"
        });

        params.options[0] = "Option 1";
        params.options[1] = "Option 2";

        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.InvalidInput.selector));
        predictionMarket.createPredictionMarket(params);

        vm.stopPrank();
    }

    // オプションが2つ未満の場合はエラー
    function testCreatePredictionMarket_InvalidInput_NoOptions() public {
        vm.startPrank(owner);
        CreatePredictionMarketParams memory params = CreatePredictionMarketParams({
            token: address(mockFanToken),
            name: "Test Market",
            expiry: block.timestamp + 1 days,
            options: new string[](1),
            entryAmount: 100 * 1e18,
            oracleDuration: 7 days,
            description: "Test Description"
        });

        params.options[0] = "Option 1";

        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.InvalidInput.selector));
        predictionMarket.createPredictionMarket(params);

        vm.stopPrank();
    }

    // 期間が1時間未満の場合はエラー
    function testCreatePredictionMarket_InvalidInput_ExpiryTooShort() public {
        vm.startPrank(owner);
        CreatePredictionMarketParams memory params = CreatePredictionMarketParams({
            token: address(mockFanToken),
            name: "Test Market",
            expiry: block.timestamp,
            options: new string[](2),
            entryAmount: 100 * 1e18,
            oracleDuration: 7 days,
            description: "Test Description"
        });

        params.options[0] = "Option 1";
        params.options[1] = "Option 2";

        vm.expectRevert(abi.encodeWithSelector(SimplePredictionMarket.InvalidInput.selector));
        predictionMarket.createPredictionMarket(params);

        vm.stopPrank();
    }
}
