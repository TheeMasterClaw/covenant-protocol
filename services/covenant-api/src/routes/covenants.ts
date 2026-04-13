import type { FastifyInstance } from "fastify";
import { covenantController } from "../controllers/covenantController";
import { createCovenantSchema, updateCovenantSchema, paginationSchema } from "../types";

export async function covenantRoutes(fastify: FastifyInstance) {
  fastify.get("/", {
    schema: {
      querystring: {
        type: "object",
        properties: {
          page: { type: "integer", default: 1 },
          limit: { type: "integer", default: 20 },
          sortBy: { type: "string", default: "createdAt" },
          order: { type: "string", enum: ["asc", "desc"], default: "desc" },
          status: { type: "string" },
          chainId: { type: "integer" },
          creatorAddress: { type: "string" },
        },
      },
    },
    handler: covenantController.list,
  });

  fastify.get("/:id", covenantController.getById);

  fastify.post("/", {
    schema: {
      body: {
        type: "object",
        required: ["address", "creatorAddress", "name", "termsHash", "chainId", "implementation"],
        properties: {
          address: { type: "string", pattern: "^0x[a-fA-F0-9]{40}$" },
          creatorAddress: { type: "string", pattern: "^0x[a-fA-F0-9]{40}$" },
          name: { type: "string", minLength: 1, maxLength: 200 },
          description: { type: "string", maxLength: 5000 },
          termsHash: { type: "string", pattern: "^0x[a-fA-F0-9]{64}$" },
          metadataUri: { type: "string", format: "uri" },
          chainId: { type: "integer", minimum: 1 },
          implementation: { type: "string", pattern: "^0x[a-fA-F0-9]{40}$" },
        },
      },
    },
    handler: covenantController.create,
  });

  fastify.patch("/:id", covenantController.update);

  fastify.get("/:id/tasks", covenantController.getTasks);

  fastify.get("/:id/participants", covenantController.getParticipants);

  fastify.delete("/:id", covenantController.remove);
}
