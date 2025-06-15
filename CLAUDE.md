# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

This is a Foundry-based Solidity project. Use these commands for development:

- `forge build` - Compile all contracts
- `forge test` - Run all tests 
- `forge test --match-test <TestName>` - Run specific test
- `forge test --match-contract <ContractName>` - Run tests for specific contract
- `forge coverage` - Generate test coverage report
- `forge clean` - Clean build artifacts

### ABI Extraction
- `./abi.sh <ContractName> <OutputPath>` - Extract ABI for a specific contract

## Architecture Overview

This is a **prediction market smart contract system** written in Solidity that allows users to create and participate in betting markets.

### Core Components

**SimplePredictionMarket.sol** - Main contract handling:
- Market creation with custom parameters (token, name, description, expiry, options, entry amounts)
- Betting logic with different market states (NotStarted → Active → Closed/OracleTimedOut)
- Reward distribution to winning option holders
- Oracle integration with timeout mechanism for expired markets
- Uses upgradeable proxy pattern with ReentrancyGuard

**Key Libraries:**
- `LMSRLib` - Implements LMSR (Logarithmic Market Scoring Rule) cost functions and pricing
- `AmountMathLib` - Handles precision-based amount calculations
- Uses Solmate for ERC20 tokens and SafeTransfer utilities
- Uses OpenZeppelin upgradeable contracts for security patterns

**Market Flow:**
1. Market creation with specified parameters and oracle duration
2. Users bet on different options during active period
3. Market resolves either through oracle setting or timeout
4. Winners claim rewards, or users can redeem if oracle timed out

### Dependencies

- **Solmate** - Gas-optimized Solidity utilities (ERC20, SafeTransferLib)
- **OpenZeppelin Upgradeable** - Security patterns and upgradeability
- **Foundry** - Development framework and testing

The project uses Japanese comments in the main contract but English elsewhere. Tests are organized by functionality (Bet, ClaimReward, CloseMarket, CreatePredictionMarket, Redeem) with scenario-based integration tests.