// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library DrawLib {
    error NoCardsAvailable();

    function drawCardId(uint256[] memory cardIds, uint256[] memory amounts, uint256 totalAmount, address user)
        internal
        view
        returns (uint256 selectedCardId, uint256 selectedIndex)
    {
        if (totalAmount == 0) {
            revert NoCardsAvailable();
        }

        uint256 randomIndex =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, user))) % totalAmount;

        uint256 currentSum = 0;

        for (uint256 i = 0; i < cardIds.length; i++) {
            currentSum += amounts[i];
            if (randomIndex < currentSum) {
                return (cardIds[i], i);
            }
        }

        revert NoCardsAvailable(); // Fallback safety
    }
}
