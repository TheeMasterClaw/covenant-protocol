import type { FastifyRequest, FastifyReply } from "fastify";

export async function authMiddleware(request: FastifyRequest, reply: FastifyReply) {
  // TODO: Implement SIWE (Sign-In with Ethereum) or JWT verification
  // For now, this is a placeholder for auth middleware

  const authHeader = request.headers.authorization;

  if (!authHeader) {
    // Allow unauthenticated requests for public endpoints
    return;
  }

  // Example JWT or SIWE verification
  // const token = authHeader.replace("Bearer ", "");
  // const verified = await verifyAuth(token);
  // request.user = verified;
}

export async function requireAuth(request: FastifyRequest, reply: FastifyReply) {
  const authHeader = request.headers.authorization;

  if (!authHeader) {
    return reply.status(401).send({
      statusCode: 401,
      error: "Unauthorized",
      message: "Authentication required",
    });
  }

  // TODO: Implement actual auth verification
  // request.user = await verifyAuth(authHeader);
}
