import type { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../index";
import { createCovenantSchema, updateCovenantSchema, paginationSchema } from "../types";
import { buildPagination, buildMeta } from "../utils/pagination";

export const covenantController = {
  async list(request: FastifyRequest, reply: FastifyReply) {
    const query = request.query as any;
    const { page, limit, sortBy, order } = paginationSchema.parse(query);
    const pagination = buildPagination({ page, limit, sortBy, order });

    const where: any = {};
    if (query.status) where.status = query.status;
    if (query.chainId) where.chainId = Number(query.chainId);
    if (query.creatorAddress) where.creatorAddress = query.creatorAddress.toLowerCase();

    const [data, total] = await Promise.all([
      prisma.covenant.findMany({
        where,
        ...pagination,
        include: {
          _count: { select: { participants: true, tasks: true } },
        },
      }),
      prisma.covenant.count({ where }),
    ]);

    return reply.send({ data, meta: buildMeta(total, page, limit) });
  },

  async getById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const covenant = await prisma.covenant.findUnique({
      where: { id: request.params.id },
      include: {
        participants: { include: { user: true } },
        tasks: { take: 50 },
        events: { orderBy: { blockNumber: "desc" }, take: 20 },
      },
    });
    if (!covenant) return reply.status(404).send({ error: "Covenant not found" });
    return reply.send(covenant);
  },

  async create(request: FastifyRequest<{ Body: any }>, reply: FastifyReply) {
    const input = createCovenantSchema.parse(request.body);

    const user = await prisma.user.upsert({
      where: { address: input.creatorAddress.toLowerCase() },
      update: { totalCovenants: { increment: 1 } },
      create: { address: input.creatorAddress.toLowerCase(), totalCovenants: 1 },
    });

    const covenant = await prisma.covenant.create({
      data: {
        address: input.address.toLowerCase(),
        creatorAddress: input.creatorAddress.toLowerCase(),
        name: input.name,
        description: input.description,
        termsHash: input.termsHash.toLowerCase(),
        metadataUri: input.metadataUri,
        chainId: input.chainId,
        implementation: input.implementation.toLowerCase(),
      },
    });

    await prisma.covenantParticipant.create({
      data: {
        covenantId: covenant.id,
        userId: user.id,
        role: "OWNER",
      },
    });

    return reply.status(201).send(covenant);
  },

  async update(request: FastifyRequest<{ Params: { id: string }; Body: any }>, reply: FastifyReply) {
    const input = updateCovenantSchema.parse(request.body);
    const covenant = await prisma.covenant.update({
      where: { id: request.params.id },
      data: input,
    });
    return reply.send(covenant);
  },

  async remove(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    await prisma.covenant.delete({ where: { id: request.params.id } });
    return reply.status(204).send();
  },

  async getTasks(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const tasks = await prisma.task.findMany({
      where: { covenantId: request.params.id },
      orderBy: { createdAt: "desc" },
      include: { creator: true, assignee: true },
    });
    return reply.send(tasks);
  },

  async getParticipants(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const participants = await prisma.covenantParticipant.findMany({
      where: { covenantId: request.params.id },
      include: { user: true },
    });
    return reply.send(participants);
  },
};
