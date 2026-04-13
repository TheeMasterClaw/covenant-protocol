# COVENANT Protocol — Covenant API

Fastify-based REST API for covenant and core protocol services.

## Features

- Covenant CRUD & search
- Task management
- User & reputation lookups
- Prisma + PostgreSQL
- Swagger/OpenAPI docs
- Rate limiting & CORS
- TypeScript throughout

## Quick Start

```bash
npm install
npx prisma generate
npm run db:migrate
npm run dev
```

## Environment

```bash
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://user:pass@localhost:5432/covenant
CORS_ORIGIN=*
RATE_LIMIT_MAX=100
```

## Endpoints

- `GET /health` — health check
- `GET /covenants` — list covenants
- `GET /covenants/:id` — covenant detail
- `POST /covenants` — create covenant
- `GET /tasks` — list tasks
- `GET /tasks/:id` — task detail
- `GET /users/:address` — user profile
- `GET /reputation/:address` — reputation score

## Docker

```bash
docker build -t covenant-api .
docker run -p 3000:3000 --env-file .env covenant-api
```
