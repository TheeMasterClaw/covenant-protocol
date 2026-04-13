import type { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../index";

export const userController = {
  async getByAddress(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const user = await prisma.user.findUnique({
      where: { address: request.params.address.toLowerCase() },
      include: {
        reputation: true,
        _count: { select: { covenantRoles: true, tasksCreated: true, tasksAssigned: true } },
      },
    });
    if (!user) return reply.status(404).send({ error: "User not found" });
    return reply.send(user);
  },

  async create(request: FastifyRequest<{ Body: { address: string; ensName?: string } }>, reply: FastifyReply) {
    const user = await prisma.user.create({
      data: {
        address: request.body.address.toLowerCase(),
        ensName: request.body.ensName,
      },
    });
    return reply.status(201).send(user);
  },

  async getCovenants(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const roles = await prisma.covenantParticipant.findMany({
      where: { user: { address: request.params.address.toLowerCase() } },
      include: { covenant: true },
    });
    return reply.send(roles);
  },

  async getTasks(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const user = await prisma.user.findUnique({
      where: { address: request.params.address.toLowerCase() },
      include: {
        tasksCreated: { take: 50, orderBy: { createdAt: "desc" } },
        tasksAssigned: { take: 50, orderBy: { createdAt: "desc" } },
      },
    });
    if (!user) return reply.status(404).send({ error: "User not found" });
    return reply.send({
      created: user.tasksCreated,
      assigned: user.tasksAssigned,
    });
  },

  async getReputation(request: FastifyRequest<{ Params: { address: string } }>, reply: FastifyReply) {
    const user = await prisma.user.findUnique({
      where: { address: request.params.address.toLowerCase() },
      include: { reputation: true },
    });
    if (!user || !user.reputation) {
      return reply.status(404).send({ error: "Reputation not found" });
    }
    return reply.send(user.reputation);
  },
};
