# COVENANT Protocol — WebSocket Server

Real-time WebSocket server for live covenant/task updates.

## Features

- Socket.IO for bidirectional events
- Room-based subscriptions (covenant, task, user)
- Redis adapter for multi-node scaling
- Event broadcasting from blockchain
- Connection health monitoring

## Quick Start

```bash
npm install
npm run dev
```

## Environment

```bash
PORT=3001
REDIS_URL=redis://localhost:6379
CORS_ORIGIN=*
LOG_LEVEL=info
```

## Events

### Client -> Server
- `subscribe:covenant` — join covenant room
- `subscribe:task` — join task room
- `subscribe:user` — join user room
- `unsubscribe` — leave rooms

### Server -> Client
- `covenant:updated` — covenant changes
- `task:updated` — task changes
- `task:assigned` — task assigned
- `task:completed` — task completed
- `reputation:updated` — score changes
- `dispute:created` — new dispute
- `dispute:resolved` — dispute resolved

## Docker

```bash
docker build -t covenant-websocket .
docker run -p 3001:3001 --env-file .env covenant-websocket
```
