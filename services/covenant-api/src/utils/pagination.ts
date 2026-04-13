import type { PaginationInput } from "../types";

export function buildPagination({ page, limit, sortBy, order }: PaginationInput) {
  const skip = (page - 1) * limit;
  return {
    skip,
    take: limit,
    orderBy: { [sortBy]: order },
  };
}

export function buildMeta(total: number, page: number, limit: number) {
  return {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
    hasNextPage: page * limit < total,
    hasPrevPage: page > 1,
  };
}
