# COVENANT Protocol — Covenants Subgraph

TheGraph subgraph for indexing COVENANT covenant contracts.

## Overview

Indexes:
- CovenantFactory events (creation, upgrades)
- CovenantRegistry events (registrations, participants)
- Individual covenant events (status changes, tasks, funds)

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

## Schema

See `schema.graphql` for entity definitions.
