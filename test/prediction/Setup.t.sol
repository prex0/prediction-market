// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/SimplePredictionMarket.sol";
import {MockCredit} from "../mocks/MockCredit.sol";
import {MockFanToken} from "../mocks/MockFanToken.sol";

contract PredictionSetup is Test {
    SimplePredictionMarket public predictionMarket;
    MockCredit public mockCredit;
    MockFanToken public mockFanToken;

    address public owner = address(0x123);
    address public alice = address(0x2);
    address public bob = address(0x3);

    uint256 public marketId1;

    function setUp() public virtual {
        mockCredit = new MockCredit();
        mockFanToken = new MockFanToken();

        // Deploy the SimplePredictionMarket contract
        predictionMarket = new SimplePredictionMarket();

        // Initialize the contract with the owner and credit token
        predictionMarket.initialize(address(mockCredit), owner);

        // マーケット作成
        vm.startPrank(owner);
        mockCredit.mint(owner, 1000 * 1e6);
        mockCredit.approve(address(predictionMarket), 1000 * 1e6);

        mockFanToken.mint(owner, 10000 * 1e18);
        mockFanToken.approve(address(predictionMarket), 10000 * 1e18);

        marketId1 = createMarket();

        vm.stopPrank();
    }

    function createMarket() internal returns (uint256) {
        // 1000でマーケットを作成
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

        return predictionMarket.createPredictionMarket(params);
    }
}
