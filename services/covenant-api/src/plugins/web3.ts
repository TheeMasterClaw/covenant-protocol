import fp from "fastify-plugin";
import { createPublicClient, http } from "viem";
import type { FastifyInstance } from "fastify";

export const web3Plugin = fp(async (fastify: FastifyInstance) => {
  const rpcUrl = fastify.config.WEB3_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/demo";

  const client = createPublicClient({
    transport: http(rpcUrl),
  });

  fastify.decorate("web3", client);
});

declare module "fastify" {
  interface FastifyInstance {
    web3: ReturnType<typeof createPublicClient>;
  }
}
