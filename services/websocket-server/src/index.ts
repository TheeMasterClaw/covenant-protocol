import { createServer } from "http";
import { Server } from "socket.io";
import Redis from "ioredis";
import pino from "pino";

import { setupHandlers } from "./handlers";
import { setupRedisAdapter } from "./adapters/redis";

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  transport: process.env.NODE_ENV === "development" ? { target: "pino-pretty" } : undefined,
});

const PORT = Number(process.env.PORT || 3001);
const CORS_ORIGIN = process.env.CORS_ORIGIN || "*";
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

const redis = new Redis(REDIS_URL);
const redisPub = new Redis(REDIS_URL);

async function startServer() {
  const httpServer = createServer((req, res) => {
    if (req.url === "/health" && req.method === "GET") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "healthy", service: "websocket-server", timestamp: new Date().toISOString() }));
      return;
    }
    res.writeHead(404);
    res.end("Not Found");
  });
  const io = new Server(httpServer, {
    cors: { origin: CORS_ORIGIN, methods: ["GET", "POST"] },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  await setupRedisAdapter(io, REDIS_URL);

  io.on("connection", (socket) => {
    logger.info({ socketId: socket.id, ip: socket.handshake.address }, "Client connected");
    setupHandlers(io, socket, logger);
  });

  redis.subscribe("covenant:events", "task:events", "reputation:events", "dispute:events", (err) => {
    if (err) logger.error(err, "Failed to subscribe to Redis channels");
    else logger.info("Subscribed to Redis channels");
  });

  redis.on("message", (channel, message) => {
    try {
      const data = JSON.parse(message);
      if (channel === "covenant:events") {
        io.to(`covenant:${data.covenantId}`).emit("covenant:updated", data);
      } else if (channel === "task:events") {
        io.to(`task:${data.taskId}`).to(`covenant:${data.covenantId}`).emit("task:updated", data);
        if (data.event === "assigned") io.to(`user:${data.assignee}`).emit("task:assigned", data);
        if (data.event === "completed") io.to(`user:${data.creator}`).emit("task:completed", data);
      } else if (channel === "reputation:events") {
        io.to(`user:${data.userAddress}`).emit("reputation:updated", data);
      } else if (channel === "dispute:events") {
        io.to(`task:${data.taskId}`).to(`covenant:${data.covenantId}`).emit(
          data.event === "created" ? "dispute:created" : "dispute:resolved",
          data
        );
      }
    } catch (err) {
      logger.error(err, "Failed to process Redis message");
    }
  });

  httpServer.listen(PORT, () => {
    logger.info(`WebSocket server listening on port ${PORT}`);
  });

  process.on("SIGTERM", async () => {
    logger.info("SIGTERM received, shutting down gracefully");
    io.close(() => {
      redis.disconnect();
      redisPub.disconnect();
      httpServer.close(() => {
        process.exit(0);
      });
    });
  });
}

startServer().catch((err) => {
  logger.error(err, "Failed to start server");
  process.exit(1);
});

export { redis, redisPub };
