import type { FastifyInstance } from "fastify";
import { prisma } from "../index";

export async function healthRoutes(fastify: FastifyInstance) {
  fastify.get("/", async (request, reply) => {
    const dbHealthy = await prisma.$queryRaw`SELECT 1`.then(() => true).catch(() => false);
    const healthy = dbHealthy;

    return reply.status(healthy ? 200 : 503).send({
      status: healthy ? "healthy" : "unhealthy",
      timestamp: new Date().toISOString(),
      services: {
        database: dbHealthy ? "up" : "down",
      },
    });
  });

  fastify.get("/ready", async (request, reply) => {
    const dbHealthy = await prisma.$queryRaw`SELECT 1`.then(() => true).catch(() => false);
    return reply.status(dbHealthy ? 200 : 503).send({
      ready: dbHealthy,
    });
  });
}
