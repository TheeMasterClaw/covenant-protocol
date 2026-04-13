import { BigInt } from "@graphprotocol/graph-ts";
import {
  TaskCreated,
  TaskAssigned,
  TaskSubmitted,
  TaskCompleted,
  TaskCancelled,
  TaskDisputed,
  BidPlaced,
  BidAccepted,
  PlatformFeeUpdated,
} from "../generated/TaskMarket/TaskMarket";
import { Task, TaskMarket, TaskBid, TaskEvent, TaskAssignment } from "../generated/schema";

function getOrCreateTaskMarket(): TaskMarket {
  let market = TaskMarket.load("market");
  if (!market) {
    market = new TaskMarket("market");
    market.address = new BigInt(0) as any;
    market.totalTasks = BigInt.zero();
    market.totalValueLocked = BigInt.zero();
    market.totalCompleted = BigInt.zero();
    market.totalDisputed = BigInt.zero();
    market.activeTasks = BigInt.zero();
    market.platformFeeBps = BigInt.zero();
    market.paused = false;
    market.save();
  }
  return market;
}

function createTaskEvent(task: Task, eventType: string, emitter: any, data: string, event: any): void {
  let taskEvent = new TaskEvent(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString()
  );
  taskEvent.task = task.id;
  taskEvent.eventType = eventType;
  taskEvent.emitter = emitter;
  taskEvent.data = data;
  taskEvent.blockNumber = event.block.number;
  taskEvent.blockTimestamp = event.block.timestamp;
  taskEvent.transactionHash = event.transaction.hash;
  taskEvent.save();
}

export function handleTaskCreated(event: TaskCreated): void {
  let market = getOrCreateTaskMarket();
  market.totalTasks = market.totalTasks.plus(BigInt.fromI32(1));
  market.activeTasks = market.activeTasks.plus(BigInt.fromI32(1));
  market.save();

  let task = new Task(event.params.taskId.toString());
  task.taskId = event.params.taskId;
  task.covenant = event.params.covenant;
  task.creator = event.params.creator;
  task.title = event.params.title;
  task.description = "";
  task.reward = event.params.reward;
  task.deadline = event.params.deadline;
  task.status = "OPEN";
  task.priority = BigInt.fromI32(1);
  task.createdAt = event.block.timestamp;
  task.escrowAmount = BigInt.zero();
  task.reviewCount = BigInt.zero();
  task.averageRating = BigInt.zero();
  task.skillsRequired = [];
  task.chainId = BigInt.fromI32(1);
  task.blockNumber = event.block.number;
  task.transactionHash = event.transaction.hash;
  task.save();

  createTaskEvent(task, "TaskCreated", event.address, event.params.title, event);
}

export function handleTaskAssigned(event: TaskAssigned): void {
  let task = Task.load(event.params.taskId.toString());
  if (task) {
    task.assignee = event.params.assignee;
    task.status = "ASSIGNED";
    task.assignedAt = event.block.timestamp;
    task.save();

    let assignment = new TaskAssignment(
      event.params.taskId.toString() + "-" + event.params.assignee.toHex()
    );
    assignment.task = task.id;
    assignment.assignee = event.params.assignee;
    assignment.assignedBy = event.params.covenant;
    assignment.assignedAt = event.block.timestamp;
    assignment.escrowAmount = event.params.escrowAmount;
    assignment.blockNumber = event.block.number;
    assignment.save();

    createTaskEvent(task, "TaskAssigned", event.address, event.params.assignee.toHex(), event);
  }
}

export function handleTaskSubmitted(event: TaskSubmitted): void {
  let task = Task.load(event.params.taskId.toString());
  if (task) {
    task.status = "SUBMITTED";
    task.submittedAt = event.block.timestamp;
    task.save();
    createTaskEvent(task, "TaskSubmitted", event.address, event.params.proofHash, event);
  }
}

export function handleTaskCompleted(event: TaskCompleted): void {
  let task = Task.load(event.params.taskId.toString());
  if (task) {
    task.status = "COMPLETED";
    task.completedAt = event.block.timestamp;
    task.save();

    let market = getOrCreateTaskMarket();
    market.totalCompleted = market.totalCompleted.plus(BigInt.fromI32(1));
    market.activeTasks = market.activeTasks.minus(BigInt.fromI32(1));
    market.save();

    createTaskEvent(task, "TaskCompleted", event.address, "", event);
  }
}

export function handleTaskCancelled(event: TaskCancelled): void {
  let task = Task.load(event.params.taskId.toString());
  if (task) {
    task.status = "CANCELLED";
    task.cancelledAt = event.block.timestamp;
    task.save();

    let market = getOrCreateTaskMarket();
    market.activeTasks = market.activeTasks.minus(BigInt.fromI32(1));
    market.save();

    createTaskEvent(task, "TaskCancelled", event.address, event.params.reason, event);
  }
}

export function handleTaskDisputed(event: TaskDisputed): void {
  let task = Task.load(event.params.taskId.toString());
  if (task) {
    task.status = "DISPUTED";
    task.disputeId = event.params.disputeId;
    task.save();

    let market = getOrCreateTaskMarket();
    market.totalDisputed = market.totalDisputed.plus(BigInt.fromI32(1));
    market.save();

    createTaskEvent(task, "TaskDisputed", event.address, event.params.disputeId.toString(), event);
  }
}

export function handleBidPlaced(event: BidPlaced): void {
  let bid = new TaskBid(
    event.params.taskId.toString() + "-" + event.params.bidder.toHex() + "-" + event.logIndex.toString()
  );
  bid.task = event.params.taskId.toString();
  bid.bidder = event.params.bidder;
  bid.amount = event.params.amount;
  bid.proposal = event.params.proposal;
  bid.createdAt = event.block.timestamp;
  bid.accepted = false;
  bid.blockNumber = event.block.number;
  bid.save();
}

export function handleBidAccepted(event: BidAccepted): void {
  let bid = TaskBid.load(
    event.params.taskId.toString() + "-" + event.params.bidder.toHex() + "-" + event.logIndex.toString()
  );
  if (bid) {
    bid.accepted = true;
    bid.save();
  }
}

export function handlePlatformFeeUpdated(event: PlatformFeeUpdated): void {
  let market = getOrCreateTaskMarket();
  market.platformFeeBps = event.params.newFeeBps;
  market.save();
}
