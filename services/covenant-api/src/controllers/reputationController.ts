import type { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../index";

export const reputationController = {
  async getByAddress(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const reputation = await prisma.reputationScore.findFirst({
      where: { user: { address: request.params.address.toLowerCase() } },
      include: { user: { select: { address: true, ensName: true } } },
    });
    if (!reputation) return reply.status(404).send({ error: "Reputation not found" });
    return reply.send(reputation);
  },

  async getLeaderboard(request: FastifyRequest, reply: FastifyReply) {
    const query = request.query as any;
    const limit = Math.min(Number(query.limit) || 100, 500);
    const offset = Number(query.offset) || 0;

    const leaders = await prisma.reputationScore.findMany({
      orderBy: { score: "desc" },
      take: limit,
      skip: offset,
      include: { user: { select: { address: true, ensName: true } } },
    });

    return reply.send(leaders);
  },

  async getHistory(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const history: any[] = [];
    return reply.send(history);
  },
};
