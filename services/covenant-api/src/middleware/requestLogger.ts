import type { FastifyRequest, FastifyReply } from "fastify";

export async function requestLogger(request: FastifyRequest, reply: FastifyReply) {
  request.log.info({
    req: {
      method: request.method,
      url: request.url,
      remoteAddress: request.ip,
      headers: {
        "user-agent": request.headers["user-agent"],
        "content-type": request.headers["content-type"],
      },
    },
  }, "incoming request");

  reply.then(
    () => {
      request.log.info({
        res: {
          statusCode: reply.statusCode,
        },
        responseTime: reply.getResponseTime(),
      }, "request completed");
    },
    () => {}
  );
}
