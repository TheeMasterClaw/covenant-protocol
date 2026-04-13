import type { Server, Socket } from "socket.io";
import type { Logger } from "pino";

export function setupHandlers(io: Server, socket: Socket, logger: Logger) {
  socket.on("subscribe:covenant", (covenantId: string) => {
    socket.join(`covenant:${covenantId}`);
    logger.debug({ socketId: socket.id, covenantId }, "Subscribed to covenant");
    socket.emit("subscribed", { room: `covenant:${covenantId}` });
  });

  socket.on("subscribe:task", (taskId: string) => {
    socket.join(`task:${taskId}`);
    logger.debug({ socketId: socket.id, taskId }, "Subscribed to task");
    socket.emit("subscribed", { room: `task:${taskId}` });
  });

  socket.on("subscribe:user", (userAddress: string) => {
    socket.join(`user:${userAddress.toLowerCase()}`);
    logger.debug({ socketId: socket.id, userAddress }, "Subscribed to user");
    socket.emit("subscribed", { room: `user:${userAddress.toLowerCase()}` });
  });

  socket.on("unsubscribe", (room: string) => {
    socket.leave(room);
    logger.debug({ socketId: socket.id, room }, "Unsubscribed");
    socket.emit("unsubscribed", { room });
  });

  socket.on("ping", (callback) => {
    if (typeof callback === "function") callback({ time: Date.now() });
  });

  socket.on("disconnect", (reason) => {
    logger.info({ socketId: socket.id, reason }, "Client disconnected");
  });

  socket.on("error", (err) => {
    logger.error({ socketId: socket.id, err }, "Socket error");
  });
}
