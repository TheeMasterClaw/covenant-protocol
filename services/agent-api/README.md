# COVENANT Protocol — Agent API

FastAPI-based AI Agent Orchestrator for COVENANT Protocol.

## Features

- Agent registry and management
- Multi-agent coordination
- Task assignment to agents
- LLM integrations (OpenAI, Anthropic)
- LangChain integration
- Async task processing with Celery
- Web3 integration for on-chain actions
- Prometheus metrics & Sentry error tracking

## Quick Start

```bash
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

## Environment

```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/covenant_agents
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-...
WEB3_RPC_URL=https://...
SENTRY_DSN=...
LOG_LEVEL=info
```

## Endpoints

- `GET /health` — health check
- `GET /agents` — list registered agents
- `POST /agents` — register new agent
- `GET /agents/:id` — agent details
- `POST /agents/:id/execute` — execute agent task
- `POST /coordinations` — create coordination session
- `POST /tasks/assign` — assign task to agent
- `GET /tasks/:id/status` — task execution status

## Docker

```bash
docker build --target production -t covenant-agent-api .
docker run -p 8000:8000 --env-file .env covenant-agent-api
```

## Architecture

- `app/` — FastAPI application
- `agents/` — Agent implementations
- `core/` — Core services (coordination, registry)
- `tests/` — Test suite
