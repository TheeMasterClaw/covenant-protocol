import type { FastifyInstance } from "fastify";
import { taskController } from "../controllers/taskController";

export async function taskRoutes(fastify: FastifyInstance) {
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
          covenantId: { type: "string" },
          assigneeId: { type: "string" },
        },
      },
    },
    handler: taskController.list,
  });

  fastify.get("/:id", taskController.getById);
  fastify.post("/", taskController.create);
  fastify.patch("/:id", taskController.update);
  fastify.delete("/:id", taskController.remove);

  fastify.post("/:id/submissions", taskController.addSubmission);
  fastify.get("/:id/submissions", taskController.getSubmissions);
  fastify.get("/:id/reviews", taskController.getReviews);
}
