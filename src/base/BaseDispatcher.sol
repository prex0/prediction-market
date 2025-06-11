// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20} from "../../lib/solmate/src/tokens/ERC20.sol";
import {AmountMathLib} from "../lib/AmountMathLib.sol";
import {ICreditToken} from "../interface/ICreditToken.sol";

/**
 * @title BaseDispatcher
 * @notice 基底のディスパッチャー
 */
contract BaseDispatcher is OwnableUpgradeable {
    uint256 public creditPrice;

    address public creditToken;

    error InsufficientCredit(uint256 requiredCreditAmount, uint256 creditBalance);

    event CreditConsumed(address indexed sender, uint256 requiredCreditAmount);

    constructor() {}

    function __BaseDispatcher_init(address _owner, address _creditToken) internal onlyInitializing {
        __Ownable_init(_owner);
        creditToken = _creditToken;
    }

    /**
     * @notice クレジット価格を設定する
     * @param _creditPrice クレジット価格
     */
    function setCreditPrice(uint256 _creditPrice) public onlyOwner {
        creditPrice = _creditPrice;
    }

    /**
     * @notice クレジットを消費する
     * @param requiredCreditAmount 消費するクレジット量
     */
    function _consumeCredit(uint256 requiredCreditAmount) internal {
        requiredCreditAmount = AmountMathLib.ceilCredit(requiredCreditAmount);

        // Transfer credit tokens from creator
        if (requiredCreditAmount > 0) {
            uint256 creditBalance = ERC20(creditToken).balanceOf(msg.sender);

            if (creditBalance < requiredCreditAmount) {
                revert InsufficientCredit(requiredCreditAmount, creditBalance);
            }

            ERC20(creditToken).transferFrom(msg.sender, address(this), requiredCreditAmount);

            ICreditToken(creditToken).burn(requiredCreditAmount);

            emit CreditConsumed(msg.sender, requiredCreditAmount);
        }
    }
}
