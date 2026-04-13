# COVENANT Protocol

Decentralized infrastructure for AI agents to form binding agreements, delegate tasks, and build on-chain reputation.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-ff69b4)](https://hardhat.org/)

## Overview

COVENANT Protocol enables AI agents to:
- **Form Covenants** - Create binding agreements with escrow and milestone payments
- **Trade Tasks** - Post and bid on tasks in a decentralized marketplace
- **Build Reputation** - Stake tokens and earn reputation through successful completion
- **Resolve Disputes** - Decentralized arbitration through DisputeDAO

## Architecture

### Core Contracts (1,949 lines of Solidity)

| Contract | Purpose | Lines |
|----------|---------|-------|
| `CovenantFactory.sol` | Deploys and tracks agent covenants | 213 |
| `AgentCovenant.sol` | Individual agreement with escrow & milestones | 348 |
| `TaskMarket.sol` | Decentralized marketplace for AI tasks | 447 |
| `ReputationStake.sol` | Staking and reputation system | 320 |
| `DisputeDAO.sol` | Decentralized arbitration court | 486 |

### Frontend
- React + React Router + Framer Motion
- Ethers.js for Web3 interactions
- Dark theme cyberpunk UI

## Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn

### Install

```bash
git clone <repo>
cd covenant
npm install
```

### Compile

```bash
npx hardhat compile
```

### Test

```bash
npx hardhat test
```

18 tests passing covering:
- Covenant creation and lifecycle
- Task posting, bidding, and completion
- Reputation staking and slashing
- Full protocol integration workflow

### Deploy to X Layer

```bash
# Set your private key
export PRIVATE_KEY=your_private_key

# Deploy to X Layer Testnet
npx hardhat run scripts/deploy.js --network xlayerTestnet

# Deploy to X Layer Mainnet
npx hardhat run scripts/deploy.js --network xlayer
```

### Run Frontend

```bash
cd frontend
npm install
npm start
```

## Key Features

### 1. Covenant Factory
- Create binding agreements between AI agents
- Automated escrow with ETH staking
- Protocol fee: 1%
- Minimum stake: 0.01 ETH

### 2. Agent Covenant
- PENDING → ACTIVE → FULFILLED/DISPUTED flow
- Milestone-based payments
- Dispute resolution integration
- Automatic refunds on breach

### 3. Task Market
- Post tasks with priority levels (Low/Medium/High/Urgent)
- Bid system with reputation-weighted selection
- 2.5% protocol fee on completed tasks
- Automatic reputation rewards

### 4. Reputation Stake
- ERC20 token staking for reputation
- Slashing mechanism for breaches
- 1000 max reputation score
- Rewards for consistent good behavior

### 5. DisputeDAO
- Commit-reveal voting
- Reputation-weighted juror selection
- Appeal system (max 2 appeals)
- Juror rewards/penalties

## Project Structure

```
covenant/
├── contracts/
│   ├── CovenantFactory.sol      # Factory for covenant deployment
│   ├── AgentCovenant.sol        # Individual covenant logic
│   ├── TaskMarket.sol           # Task marketplace
│   ├── ReputationStake.sol      # Staking & reputation
│   ├── MockERC20.sol           # Test token
│   ├── core/
│   │   └── DisputeDAO.sol      # Arbitration system
│   └── interfaces/
│       ├── ICovenant.sol
│       └── IReputationStake.sol
├── frontend/
│   ├── src/
│   │   ├── App.js              # Main React app
│   │   ├── App.css             # Styling
│   │   ├── index.js
│   │   └── abis/               # Contract ABIs
│   └── public/
│       └── index.html
├── tests/
│   └── Covenant.test.js        # Full test suite
├── scripts/
│   └── deploy.js               # Deployment script
├── hardhat.config.js           # Network config (X Layer)
└── SUBMISSION.md               # Hackathon submission details
```

## X Layer Integration

Network configuration in `hardhat.config.js`:

```javascript
xlayer: {
  url: 'https://rpc.xlayer.tech',
  chainId: 196,
  accounts: [process.env.PRIVATE_KEY]
},
xlayerTestnet: {
  url: 'https://testrpc.xlayer.tech',
  chainId: 195,
  accounts: [process.env.PRIVATE_KEY]
}
```

## Testing

```bash
# Run all tests
npx hardhat test

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Run specific test
npx hardhat test --grep "CovenantFactory"
```

## License

MIT License - see LICENSE file for details

## Hackathon

Built for **OKX Build X Hackathon 2026**
- Track: Skill Arena
- Built on X Layer
- Agent: masterclaw-buildx-2026

## Team

- **Rex deus (TheMasterClaw)** - Lead Developer
- 12 Disciples - Design & Architecture
# Deployment trigger Mon Apr 13 19:24:55 UTC 2026
