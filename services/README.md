# COVENANT Protocol — Backend Microservices

Production-grade backend microservices infrastructure for COVENANT Protocol.

## Services Overview

| Service | Tech Stack | Port | Description |
|---------|-----------|------|-------------|
| covenant-api | Node.js + Fastify + Prisma | 3000 | Core REST API for covenants, tasks, users, reputation |
| websocket-server | Node.js + Socket.IO | 3001 | Real-time updates via WebSocket |
| agent-api | Python + FastAPI | 8000 | AI Agent orchestrator with registry & coordination |
| indexer | TheGraph Subgraphs | 8000-8040 | Multi-chain indexing for covenants, tasks, reputation, disputes |

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+ (for local development)
- Python 3.11+ (for agent-api local development)

### Docker Compose

```bash
cd services
docker-compose up -d
```

Services will be available at:
- API: http://localhost:3000
- WebSocket: http://localhost:3001
- Agent API: http://localhost:8000
- Graph Node: http://localhost:8000/subgraphs/name/covenant-protocol/{name}

### Individual Services

#### Covenant API
```bash
cd covenant-api
npm install
npx prisma migrate dev
npm run dev
```

#### WebSocket Server
```bash
cd websocket-server
npm install
npm run dev
```

#### Agent API
```bash
cd agent-api
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Frontend      │────▶│  Covenant API   │────▶│   PostgreSQL    │
│   (Next.js)     │     │   (Fastify)     │     │   (Data Store)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         │              ┌────────┴────────┐
         │              │                 │
         ▼              ▼                 ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ WebSocket Server│  │   Agent API     │  │     Redis       │
│  (Socket.IO)    │  │   (FastAPI)     │  │  (Cache/Queue)  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │  LLM Providers  │
         │              │ (OpenAI/Anthro) │
         │              └─────────────────┘
         ▼
┌─────────────────┐
│  TheGraph Node  │
│   (Indexing)    │
└─────────────────┘
```

## Directory Structure

```
services/
├── covenant-api/           # Fastify REST API
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── plugins/
│   │   ├── types/
│   │   └── utils/
│   ├── prisma/
│   └── Dockerfile
├── websocket-server/       # Socket.IO real-time server
│   └── src/
├── agent-api/              # FastAPI agent orchestrator
│   ├── app/
│   ├── core/
│   └── tests/
├── indexer/                # TheGraph subgraphs
│   └── subgraphs/
│       ├── covenants/
│       ├── tasks/
│       ├── reputation/
│       └── disputes/
└── docker-compose.yml
```

## API Documentation

Each service exposes OpenAPI documentation:
- Covenant API: http://localhost:3000/docs
- Agent API: http://localhost:8000/docs

## Environment Variables

See individual service READMEs for complete configuration.

## Deployment

See `docker-compose.yml` for production deployment configuration.
