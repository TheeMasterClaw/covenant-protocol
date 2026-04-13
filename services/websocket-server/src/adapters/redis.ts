import type { Server } from "socket.io";
import { createAdapter } from "@socket.io/redis-adapter";
import Redis from "ioredis";

export async function setupRedisAdapter(io: Server, redisUrl: string) {
  const pubClient = new Redis(redisUrl);
  const subClient = pubClient.duplicate();
  io.adapter(createAdapter(pubClient, subClient));
}
