import type { FastifyInstance } from "fastify";
import { reputationController } from "../controllers/reputationController";

export async function reputationRoutes(fastify: FastifyInstance) {
  fastify.get("/leaderboard", reputationController.getLeaderboard);
  fastify.get("/:address", reputationController.getByAddress);
  fastify.get("/:address/history", reputationController.getHistory);
}
