import type { FastifyInstance } from "fastify";
import { userController } from "../controllers/userController";

export async function userRoutes(fastify: FastifyInstance) {
  fastify.get("/:address", userController.getByAddress);
  fastify.get("/:address/covenants", userController.getCovenants);
  fastify.get("/:address/tasks", userController.getTasks);
  fastify.get("/:address/reputation", userController.getReputation);

  fastify.post("/", {
    schema: {
      body: {
        type: "object",
        required: ["address"],
        properties: {
          address: { type: "string", pattern: "^0x[a-fA-F0-9]{40}$" },
          ensName: { type: "string" },
        },
      },
    },
    handler: userController.create,
  });
}
