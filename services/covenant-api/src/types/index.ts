import { z } from "zod";

export const createCovenantSchema = z.object({
  address: z.string().regex(/^0x[a-fA-F0-9]{40}$/),
  creatorAddress: z.string().regex(/^0x[a-fA-F0-9]{40}$/),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  termsHash: z.string().regex(/^0x[a-fA-F0-9]{64}$/),
  metadataUri: z.string().url().optional(),
  chainId: z.number().int().positive(),
  implementation: z.string().regex(/^0x[a-fA-F0-9]{40}$/),
});

export const updateCovenantSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(5000).optional(),
  status: z.enum(["PENDING", "ACTIVE", "PAUSED", "DISSOLVED"]).optional(),
  metadataUri: z.string().url().optional(),
});

export const createTaskSchema = z.object({
  onChainTaskId: z.string(),
  covenantId: z.string().uuid(),
  creatorId: z.string().uuid(),
  title: z.string().min(1).max(300),
  description: z.string().max(10000).optional(),
  reward: z.string().regex(/^\d+$/),
  tokenAddress: z.string().regex(/^0x[a-fA-F0-9]{40}$/).optional(),
  deadline: z.string().datetime(),
  category: z.string().max(100).optional(),
  priority: z.number().int().min(1).max(5).default(1),
  chainId: z.number().int().positive(),
});

export const updateTaskSchema = z.object({
  title: z.string().min(1).max(300).optional(),
  description: z.string().max(10000).optional(),
  status: z.enum(["OPEN", "ASSIGNED", "IN_PROGRESS", "SUBMITTED", "COMPLETED", "CANCELLED", "DISPUTED"]).optional(),
  assigneeId: z.string().uuid().optional().nullable(),
  metadataUri: z.string().url().optional(),
});

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  sortBy: z.string().default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
});

export type CreateCovenantInput = z.infer<typeof createCovenantSchema>;
export type UpdateCovenantInput = z.infer<typeof updateCovenantSchema>;
export type CreateTaskInput = z.infer<typeof createTaskSchema>;
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>;
export type PaginationInput = z.infer<typeof paginationSchema>;
