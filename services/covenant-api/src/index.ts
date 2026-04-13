import fastify from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import { PrismaClient } from "@prisma/client";

import { envPlugin } from "./plugins/env";
import { errorHandler } from "./middleware/errorHandler";
import { requestLogger } from "./middleware/requestLogger";
import { healthRoutes } from "./routes/health";
import { covenantRoutes } from "./routes/covenants";
import { taskRoutes } from "./routes/tasks";
import { userRoutes } from "./routes/users";
import { reputationRoutes } from "./routes/reputation";

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
});

async function buildApp() {
  const app = fastify({
    logger: {
      level: process.env.LOG_LEVEL || "info",
      transport: process.env.NODE_ENV === "development" ? { target: "pino-pretty" } : undefined,
    },
  });

  await app.register(envPlugin);
  await app.register(cors, { origin: app.config.CORS_ORIGIN || "*" });
  await app.register(helmet);
  await app.register(rateLimit, {
    max: Number(app.config.RATE_LIMIT_MAX || 100),
    timeWindow: "1 minute",
  });

  await app.register(swagger, {
    openapi: {
      info: {
        title: "COVENANT API",
        description: "COVENANT Protocol REST API",
        version: "1.0.0",
      },
      servers: [{ url: "http://localhost:3000" }],
    },
  });
  await app.register(swaggerUi, { routePrefix: "/docs" });

  app.setErrorHandler(errorHandler);
  app.addHook("onRequest", requestLogger);

  app.register(healthRoutes, { prefix: "/health" });
  app.register(covenantRoutes, { prefix: "/covenants" });
  app.register(taskRoutes, { prefix: "/tasks" });
  app.register(userRoutes, { prefix: "/users" });
  app.register(reputationRoutes, { prefix: "/reputation" });

  app.addHook("onClose", async () => {
    await prisma.$disconnect();
  });

  return app;
}

async function start() {
  const app = await buildApp();
  const port = Number(app.config.PORT || 3000);
  try {
    await app.listen({ port, host: "0.0.0.0" });
    app.log.info(`COVENANT API listening on ${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

if (require.main === module) {
  start();
}

export { buildApp };
