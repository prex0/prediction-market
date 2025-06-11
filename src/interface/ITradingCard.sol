// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITradingCard {
    function issuer() external view returns (address);

    function burn(uint256 id, uint256 amount) external;
}
