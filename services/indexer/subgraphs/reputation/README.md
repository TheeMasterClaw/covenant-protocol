# COVENANT Protocol — Reputation Subgraph

TheGraph subgraph for indexing COVENANT reputation system.

## Overview

Indexes:
- ReputationStake events (staking, unstaking, rewards)
- ReputationOracle events (score updates, oracle management)
- ReputationBoost events (boosts, achievements)
- ReputationDecay events (decay calculations)

## Setup

```bash
npm install
npm run codegen
npm run build
```

## Deployment

```bash
# Local
npm run create-local
npm run deploy-local

# Studio
npm run deploy
```
