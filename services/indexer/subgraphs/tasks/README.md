# COVENANT Protocol — Tasks Subgraph

TheGraph subgraph for indexing COVENANT task marketplace contracts.

## Overview

Indexes:
- TaskMarket events (creation, assignment, completion, disputes)
- TaskEscrow events (creation, release, refund)
- TaskReview events (ratings, comments)
- TaskAuction events (bids, acceptance)

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
