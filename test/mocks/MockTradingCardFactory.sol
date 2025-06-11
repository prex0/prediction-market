// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MockTradingCardFactory {
    function baseURI() external view returns (string memory) {
        return "https://example.com/";
    }
}
