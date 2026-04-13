import fp from "fastify-plugin";
import env from "@fastify/env";
import type { FastifyInstance } from "fastify";

const schema = {
  type: "object",
  required: ["DATABASE_URL"],
  properties: {
    PORT: { type: "string", default: "3000" },
    NODE_ENV: { type: "string", default: "development" },
    DATABASE_URL: { type: "string" },
    CORS_ORIGIN: { type: "string", default: "*" },
    RATE_LIMIT_MAX: { type: "string", default: "100" },
    LOG_LEVEL: { type: "string", default: "info" },
    WEB3_RPC_URL: { type: "string", default: "" },
  },
};

const options = {
  confKey: "config",
  schema,
  dotenv: true,
};

declare module "fastify" {
  interface FastifyInstance {
    config: {
      PORT: string;
      NODE_ENV: string;
      DATABASE_URL: string;
      CORS_ORIGIN: string;
      RATE_LIMIT_MAX: string;
      LOG_LEVEL: string;
      WEB3_RPC_URL: string;
    };
  }
}

export const envPlugin = fp(async (fastify: FastifyInstance) => {
  await fastify.register(env, options);
});
