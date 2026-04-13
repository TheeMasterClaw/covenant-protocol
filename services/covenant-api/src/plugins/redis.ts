import fp from "fastify-plugin";
import Redis from "ioredis";
import type { FastifyInstance } from "fastify";

export const redisPlugin = fp(async (fastify: FastifyInstance) => {
  const redis = new Redis(fastify.config.REDIS_URL || "redis://localhost:6379");

  fastify.decorate("redis", redis);

  fastify.addHook("onClose", async () => {
    await redis.quit();
  });
});

declare module "fastify" {
  interface FastifyInstance {
    redis: Redis;
  }
}
