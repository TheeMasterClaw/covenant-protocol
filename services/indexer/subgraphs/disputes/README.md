# COVENANT Protocol — Disputes Subgraph

TheGraph subgraph for indexing COVENANT dispute resolution system.

## Overview

Indexes:
- DisputeDAO events (creation, juror management, parameters)
- DisputeJury events (selection, compensation)
- DisputeEvidence events (submissions)
- DisputeVoting events (vote casting, periods)
- DisputeResolution events (resolutions, appeals, execution)

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
