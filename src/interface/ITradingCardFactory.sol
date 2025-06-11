// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITradingCardFactory {
    function baseURI() external view returns (string memory);
    function exchangeTokenForStub(address cardAddress, uint256 id, uint256 amount, address to) external;
}
