import type { FastifyInstance } from "fastify";

export function errorHandler(
  this: FastifyInstance,
  error: any,
  request: any,
  reply: any
) {
  request.log.error(error);

  const statusCode = error.statusCode || 500;
  const message = error.message || "Internal Server Error";

  if (error.code === "P2002") {
    return reply.status(409).send({
      statusCode: 409,
      error: "Conflict",
      message: "Resource already exists.",
    });
  }

  if (error.code === "P2025") {
    return reply.status(404).send({
      statusCode: 404,
      error: "Not Found",
      message: "Resource not found.",
    });
  }

  if (error.validation) {
    return reply.status(400).send({
      statusCode: 400,
      error: "Bad Request",
      message: error.message,
      validation: error.validation,
    });
  }

  reply.status(statusCode).send({
    statusCode,
    error: statusCode >= 500 ? "Internal Server Error" : error.name || "Error",
    message,
    ...(process.env.NODE_ENV === "development" && { stack: error.stack }),
  });
}
