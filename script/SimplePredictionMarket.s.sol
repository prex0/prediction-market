// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimplePredictionMarket} from "../src/SimplePredictionMarket.sol";
import "../lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeploySimplePredictionMarketScript is Script {
    SimplePredictionMarket public simplePredictionMarket;

    address public OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;
    address public CREDIT_ADDRESS = 0xC2835f0fC2f63AB2057F6e74fA213B6a0cE04C4A;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        simplePredictionMarket = new SimplePredictionMarket{salt: keccak256("Ver1")}();

        bytes memory initData =
            abi.encodeWithSelector(SimplePredictionMarket.initialize.selector, CREDIT_ADDRESS, OWNER_ADDRESS);

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(simplePredictionMarket), OWNER_ADDRESS, initData);

        // Log the addresses of the deployed contracts for verification and record-keeping purposes
        console.log("SimplePredictionMarket deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
