import type { FastifyRequest, FastifyReply } from "fastify";
import { prisma } from "../index";
import { createTaskSchema, updateTaskSchema, paginationSchema } from "../types";
import { buildPagination, buildMeta } from "../utils/pagination";

export const taskController = {
  async list(request: FastifyRequest, reply: FastifyReply) {
    const query = request.query as any;
    const { page, limit, sortBy, order } = paginationSchema.parse(query);
    const pagination = buildPagination({ page, limit, sortBy, order });

    const where: any = {};
    if (query.status) where.status = query.status;
    if (query.covenantId) where.covenantId = query.covenantId;
    if (query.assigneeId) where.assigneeId = query.assigneeId;

    const [data, total] = await Promise.all([
      prisma.task.findMany({
        where,
        ...pagination,
        include: { creator: { select: { address: true } }, assignee: { select: { address: true } } },
      }),
      prisma.task.count({ where }),
    ]);

    return reply.send({ data, meta: buildMeta(total, page, limit) });
  },

  async getById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const task = await prisma.task.findUnique({
      where: { id: request.params.id },
      include: {
        creator: true,
        assignee: true,
        reviews: true,
        submissions: { orderBy: { submittedAt: "desc" } },
        covenant: { select: { name: true, address: true } },
      },
    });
    if (!task) return reply.status(404).send({ error: "Task not found" });
    return reply.send(task);
  },

  async create(request: FastifyRequest<{ Body: any }>, reply: FastifyReply) {
    const input = createTaskSchema.parse(request.body);
    const task = await prisma.task.create({
      data: {
        onChainTaskId: input.onChainTaskId,
        covenantId: input.covenantId,
        creatorId: input.creatorId,
        title: input.title,
        description: input.description,
        reward: input.reward,
        tokenAddress: input.tokenAddress?.toLowerCase(),
        deadline: new Date(input.deadline),
        category: input.category,
        priority: input.priority,
        chainId: input.chainId,
      },
    });
    return reply.status(201).send(task);
  },

  async update(request: FastifyRequest<{ Params: { id: string }; Body: any }>, reply: FastifyReply) {
    const input = updateTaskSchema.parse(request.body);
    const data: any = { ...input };
    if (input.status === "ASSIGNED") data.assignedAt = new Date();
    if (input.status === "SUBMITTED") data.submittedAt = new Date();
    if (input.status === "COMPLETED") data.completedAt = new Date();
    if (input.status === "CANCELLED") data.cancelledAt = new Date();

    const task = await prisma.task.update({
      where: { id: request.params.id },
      data,
    });
    return reply.send(task);
  },

  async remove(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    await prisma.task.delete({ where: { id: request.params.id } });
    return reply.status(204).send();
  },

  async addSubmission(request: FastifyRequest<{ Params: { id: string }; Body: any }>, reply: FastifyReply) {
    const submission = await prisma.taskSubmission.create({
      data: {
        taskId: request.params.id,
        submitter: request.body.submitter.toLowerCase(),
        proofUri: request.body.proofUri,
        comment: request.body.comment,
      },
    });
    return reply.status(201).send(submission);
  },

  async getSubmissions(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const submissions = await prisma.taskSubmission.findMany({
      where: { taskId: request.params.id },
      orderBy: { submittedAt: "desc" },
    });
    return reply.send(submissions);
  },

  async getReviews(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    const reviews = await prisma.taskReview.findMany({
      where: { taskId: request.params.id },
      orderBy: { createdAt: "desc" },
    });
    return reply.send(reviews);
  },
};
