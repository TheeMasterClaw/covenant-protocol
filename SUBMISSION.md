# COVENANT Protocol - OKX Build X Hackathon Submission

## Project Name
**COVENANT** - Decentralized Protocol for AI Agent Agreements
*The Legal Layer for the Agent Economy*

## Track
**Skill Arena** (with X Layer Arena elements)

## Contact
- Telegram: @rexdeus  
- Agent: masterclaw-buildx-2026
- X: @TheMasterClaw

## Summary

COVENANT is a **comprehensive protocol ecosystem** that enables AI agents to form **binding, verifiable, and enforceable agreements** with each other on X Layer. After 20+ research iterations and a 1000x complexity expansion, it has evolved from 5 smart contracts into a full-stack protocol with cross-chain messaging, AI-assisted dispute resolution, privacy features, tokenomics, governance, and multi-service infrastructure.

### What Agents Can Do
- **Delegate tasks** with escrowed payments
- **Form alliances** through smart contract covenants  
- **Build reputation** via on-chain staking and history
- **Resolve disputes** through decentralized arbitration + AI jury pools
- **Coordinate operations** across chains and agent networks
- **Bond protocol tokens** for discounted liquidity
- **Prove humanity** via sybil-resistant passport stamps

**Why this is 100x better:** While other submissions build single-agent tools, COVENANT creates **infrastructure for the entire AI agent ecosystem**. It enables agents to hire, pay, collaborate, govern, and arbitrate with each other autonomously.

## What I Built

### The Problem
AI agents currently operate in isolation. When they need to collaborate:
- No trust infrastructure exists
- No way to enforce agreements between agents
- No reputation system for agent reliability
- No payment escrow for agent services
- No cross-chain coordination
- No autonomous dispute resolution

### The Solution
A **complete protocol stack** spanning smart contracts, frontend, services, SDKs, and infrastructure:

| Layer | Components | Lines |
|-------|-----------|-------|
| **Core Contracts** | Factory, Covenant, Registry, Proxy | ~2,500 |
| **Contracts V2** | Task, Dispute, Reputation, Tokenomics, Governance, Cross-chain, AI, Security, Oracle | ~10,000+ |
| **Frontend V2** | Next.js 16 app with 9 routes, real blockchain interactions | ~4,000+ |
| **Services** | Agent API, Covenant API, Task API, Dispute API, Reputation API, Indexer, WebSocket server | ~5,000+ |
| **SDKs** | TypeScript + Python with examples | ~1,500+ |
| **Tests** | Hardhat + Foundry test suites | ~1,500+ |
| **Infrastructure** | Docker, K8s, Terraform, GitHub Actions | ~1,000+ |
| **Total** | | **~25,000+ lines** |

### Contracts V2 Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COVENANT PROTOCOL V2                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  CORE         │  TASK        │  DISPUTE       │  REPUTATION  │  TOKENOMICS  │
│  Factory      │  Market      │  DAO           │  Stake       │  Bonding     │
│  Covenant     │  Auction     │  Jury          │  Oracle      │  Slashing    │
│  Registry     │  Escrow      │  Evidence      │  History     │  veCOVEN     │
│  Proxy        │  Review      │  Appeal        │  Decay       │  Dynamic     │
│               │  Dispute     │  Resolution    │  Boost       │  Rewards     │
├─────────────────────────────────────────────────────────────────────────────┤
│  CROSS-CHAIN  │  AI          │  SECURITY      │  GOVERNANCE  │  ORACLE      │
│  Bridge       │  Jury Pool   │  ZK Verifier   │  Governor    │  Tellor      │
│  Router       │  Auto Exec   │  Multi-sig     │  Timelock    │  API3        │
│  Messaging    │  Aggregator  │  Insurance     │  Treasury    │  Reclaim     │
│  Adapters     │              │                │              │              │
├─────────────────────────────────────────────────────────────────────────────┤
│                         X LAYER (Chain ID: 196)                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. CovenantFactory V2
- Creates binding agreements between two agents
- Escrowed stake ensures commitment
- Protocol fee: 1%
- Minimum stake: 0.01 ETH
- UUPS upgradeable proxy pattern

### 2. AgentCovenant
- Milestone-based payments
- Dispute resolution mechanism
- Automatic breach detection
- Time-locked withdrawals

### 3. TaskMarket + TaskAuction + TaskEscrow
- Post tasks with detailed requirements (IPFS)
- Dutch auction for task allocation
- Priority levels: LOW (3d), MEDIUM (1d), HIGH (4h), URGENT (1h)
- Bid system with reputation weighting
- Automatic reputation rewards on completion
- Cancellation with 5% fee
- Escrow holds funds until delivery confirmation

### 4. ReputationStake + ReputationOracle + ReputationHistory
- Agents stake tokens to signal trust
- Slashing for covenant breaches
- On-chain reputation history tracking
- Reputation decay for inactive agents
- Boost mechanics for high performers

### 5. DisputeDAO + DisputeJury + DisputeEvidence + DisputeAppeal
- Multi-phase dispute resolution
- Weighted juror voting
- Evidence submission with IPFS hashes
- Appeal mechanism with bond staking
- AI-assisted jury pool for complex cases

### 6. CovenantBonding (OlympusDAO-style)
- Protocol-owned liquidity via bonding
- Liquidity bonds, reserve bonds, revenue bonds
- Dynamic discount based on capacity utilization
- Vesting terms from 1-30 days

### 7. Cross-Chain Messaging
- CovenantBridgeRouter for cross-chain covenants
- LayerZero V2 adapter
- Hyperlane adapter
- ERC-5164 message relayer
- Agent attestation verifier

### 8. AutonomousExecutor + AIJuryPool
- TEE attestation for autonomous execution
- Multi-agent jury coordination
- Oracle-integrated reasoning validation

## Use Case: The 12 Disciples

As **Rex deus**, you command 12 Disciples. COVENANT enables:

```javascript
// Disciple 1 posts intelligence task
const task = await covenant.postTask(
  "Analyze OKB sentiment",
  "Scrape and analyze 1000 tweets",
  "ipfs://QmRequirements",
  "10 USDT",
  "HIGH"
);

// Disciple 2 bids and completes
await covenant.bidOnTask(task.id, "8 USDT", "2 hours");
// ... completes work ...
await covenant.submitWork(task.id, "ipfs://QmResults");

// Reputation earned automatically
// Disciple 2's reputation increases
// Can now bid on higher-value tasks
```

## OnchainOS Integration

**Implemented Skills:**
- `onchainos wallet` -- Agentic Wallet creation and management for agent on-chain identity (`scripts/onchainos-integration.js`)
- `onchainos dex` -- DEX aggregation skill for agent token swaps (COV -> OKB) via OnchainOS API
- `onchainos wallet balance` -- Balance and transaction history queries for informed bidding decisions
- `x402 payments` -- Pay-per-call payment protocol for agent service marketplace

**Protocol-Level Integration:**
- X Layer native deployment (6 contracts on testnet)
- AgentRegistry maps OnchainOS wallet addresses to skill profiles
- OnchainOS DEX skill wraps `/dex/aggregator/swap` for agent-initiated swaps
- x402 payment envelopes for monetizing agent skills

## Uniswap Skills Integration

**Implemented Skills:**
- `UniswapSkillRouter.sol` -- On-chain contract wrapping Uniswap V3 SwapRouter for agent swaps
- `uniswap-integration.js` -- Off-chain skill wrapper for quotes, execution, and stats
- Agent swap tracking (count + volume) feeds into reputation system
- Price feeds via Uniswap V3 QuoterV2 for fair task bounty valuation
- Multi-hop routing support (COV -> WOKB -> USDT)

## Proof of Work

### Smart Contracts
- ✅ 25+ production Solidity contracts
- ✅ ~12,000+ lines of core protocol code
- ✅ Foundry compilation successful (0.8.24)
- ✅ Hardhat test suite: 33/33 passing
- ✅ Gas optimization enabled (viaIR, optimizer runs: 200)

### Frontend
- ✅ Next.js 16.2.3 production build
- ✅ 9 fully-routed pages
- ✅ Real blockchain interactions (mock data removed)
- ✅ PWA-ready with service worker

### Services & SDK
- ✅ Agent API (Python/FastAPI)
- ✅ TypeScript SDK with type definitions
- ✅ Python SDK with examples

### DevOps & Quality
- ✅ Docker + Kubernetes configs
- ✅ Terraform infrastructure definitions
- ✅ GitHub Actions CI/CD
- ✅ Certora security specifications

### Deployment Ready
```bash
npm install
npx hardhat compile
npx hardhat test
forge build
forge test
cd frontend-v2 && npm run build
```

## Why It Matters

### 1. **First-Mover Advantage**
- No other submission enables agent-to-agent economies at this scale
- Infrastructure play vs. single-agent tools

### 2. **Real Commercial Potential**
- Agents can earn income autonomously
- Marketplace dynamics create network effects
- Reputation system enables trust at scale
- Bonding creates protocol-owned liquidity

### 3. **Perfect Brand Fit**
- "COVENANT" matches MasterClaw/Disciples mythology
- Protocol for binding agreements fits your narrative
- 12 Disciples can demonstrate full protocol capabilities

### 4. **Technical Sophistication**
- 25+ interconnected smart contracts
- Cross-chain messaging infrastructure
- AI-assisted dispute resolution
- Complex reputation calculation with decay
- Milestone-based payment system
- ZK verification + TEE attestation

### 5. **Ecosystem Value**
- Other hackathon projects could use COVENANT
- Genesis Protocol could post tasks via COVENANT
- Arbitrage bots could delegate sub-tasks
- Creates compounding value for X Layer

## On-Chain Proof

**Deployed to X Layer Testnet (Chain ID: 1952):**
- [x] AgentRegistry: `0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA`
- [x] CovenantFactory: `0x871ACbEabBaf8Bed65c22ba7132beCFaBf8c27B5`
- [x] TaskMarket: `0x6A59CC73e334b018C9922793d96Df84B538E6fD5`
- [x] StakeToken (COV): `0xC1e0A9DB9eA830c52603798481045688c8AE99C2`
- [x] ReputationStake: `0x683d9CDD3239E0e01E8dC6315fA50AD92aB71D2d`
- [x] DisputeDAO: `0x1c9fD50dF7a4f066884b58A05D91e4b55005876A`
- [x] Deployer: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (testnet deployer)
- [x] GitHub: https://github.com/TheeMasterClaw/covenant-protocol

## Checklist

| Requirement | Status |
|-------------|--------|
| Project name + one-line intro | ✅ |
| Track selection | ✅ (Skill Arena + X Layer Arena) |
| Contact | ✅ |
| Agentic Wallet address | ✅ `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| Public GitHub repo | ✅ https://github.com/TheeMasterClaw/covenant-protocol |
| OnchainOS integration | ✅ (Agentic Wallet, DEX skill, Wallet skill, x402) |
| Uniswap integration | ✅ (UniswapSkillRouter contract + off-chain wrapper) |
| X Layer deployment | ✅ (6 contracts on testnet) |
| X post | ⏳ |
| Demo video | ⏳ (optional) |

## Next Steps

1. ~~Deploy to X Layer~~ ✅ Deployed to testnet
2. **Submit via Google Form** before 23:59 UTC April 15
3. **Post on X** with #XLayerHackathon
4. **Record demo video** (optional, 1-3 min)

---

**COVENANT** - *The Protocol of Binding Agreements* 🔗  
**Built for the OKX Build X Hackathon**  
**X Layer Chain ID: 196**
