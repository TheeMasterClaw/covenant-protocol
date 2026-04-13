import { BaseContract } from './base';
import {
  Task,
  TaskStatus,
  Auction,
  Escrow,
  EscrowState,
  Review,
  TaskDisputeRecord,
  TaskDisputeStatus,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  TaskMarketABI,
  TaskAuctionABI,
  TaskEscrowABI,
  TaskReviewABI,
  TaskDisputeABI,
} from '../abis';

export class TaskMarket extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, TaskMarketABI, provider);
  }

  async createTask(
    covenantId: bigint,
    reward: bigint,
    rewardToken: EthereumAddress,
    deadline: bigint,
    metadataHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'createTask',
      [covenantId, reward, rewardToken, deadline, metadataHash],
      overrides
    );
  }

  async assignTask(taskId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('assignTask', [taskId], overrides);
  }

  async submitTask(
    taskId: bigint,
    proofHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('submitTask', [taskId, proofHash], overrides);
  }

  async completeTask(taskId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('completeTask', [taskId], overrides);
  }

  async disputeTask(taskId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('disputeTask', [taskId], overrides);
  }

  async cancelTask(taskId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('cancelTask', [taskId], overrides);
  }

  async getTask(taskId: bigint): Promise<Task> {
    const result = await this.call<any>('getTask', [taskId]);
    return {
      id: result.id,
      covenantId: result.covenantId,
      creator: result.creator,
      assignee: result.assignee,
      reward: result.reward,
      rewardToken: result.rewardToken,
      deadline: result.deadline,
      status: result.status,
      metadataHash: result.metadataHash,
    };
  }

  async getTasksByCovenant(covenantId: bigint): Promise<bigint[]> {
    return this.call('getTasksByCovenant', [covenantId]);
  }

  async getTasksByAssignee(assignee: EthereumAddress): Promise<bigint[]> {
    return this.call('getTasksByAssignee', [assignee]);
  }
}

export class TaskAuction extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, TaskAuctionABI, provider);
  }

  async createAuction(
    taskId: bigint,
    startPrice: bigint,
    endPrice: bigint,
    duration: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'createAuction',
      [taskId, startPrice, endPrice, duration],
      overrides
    );
  }

  async placeBid(auctionId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('placeBid', [auctionId], overrides);
  }

  async settleAuction(
    auctionId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('settleAuction', [auctionId], overrides);
  }

  async cancelAuction(
    auctionId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('cancelAuction', [auctionId], overrides);
  }

  async getCurrentPrice(auctionId: bigint): Promise<bigint> {
    return this.call('getCurrentPrice', [auctionId]);
  }

  async getAuction(auctionId: bigint): Promise<Auction> {
    const result = await this.call<any>('getAuction', [auctionId]);
    return {
      taskId: result.taskId,
      startPrice: result.startPrice,
      endPrice: result.endPrice,
      startTime: result.startTime,
      duration: result.duration,
      highestBidder: result.highestBidder,
      highestBid: result.highestBid,
      settled: result.settled,
    };
  }
}

export class TaskEscrow extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, TaskEscrowABI, provider);
  }

  async createEscrow(
    taskId: bigint,
    token: EthereumAddress,
    amount: bigint,
    payee: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'createEscrow',
      [taskId, token, amount, payee],
      overrides
    );
  }

  async fundEscrow(
    escrowId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('fundEscrow', [escrowId], overrides);
  }

  async releaseEscrow(
    escrowId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('releaseEscrow', [escrowId], overrides);
  }

  async refundEscrow(
    escrowId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('refundEscrow', [escrowId], overrides);
  }

  async disputeEscrow(
    escrowId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('disputeEscrow', [escrowId], overrides);
  }

  async getEscrow(escrowId: bigint): Promise<Escrow> {
    const result = await this.call<any>('getEscrow', [escrowId]);
    return {
      taskId: result.taskId,
      amount: result.amount,
      token: result.token,
      payer: result.payer,
      payee: result.payee,
      state: result.state,
    };
  }

  async getEscrowByTask(taskId: bigint): Promise<bigint> {
    return this.call('getEscrowByTask', [taskId]);
  }
}

export class TaskReview extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, TaskReviewABI, provider);
  }

  async submitReview(
    taskId: bigint,
    reviewee: EthereumAddress,
    rating: number,
    commentHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'submitReview',
      [taskId, reviewee, rating, commentHash],
      overrides
    );
  }

  async updateReview(
    reviewId: bigint,
    newRating: number,
    newCommentHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'updateReview',
      [reviewId, newRating, newCommentHash],
      overrides
    );
  }

  async getReview(reviewId: bigint): Promise<Review> {
    const result = await this.call<any>('getReview', [reviewId]);
    return {
      reviewId: result.reviewId,
      taskId: result.taskId,
      reviewer: result.reviewer,
      reviewee: result.reviewee,
      rating: result.rating,
      commentHash: result.commentHash,
      createdAt: result.createdAt,
    };
  }

  async getReviewsByTask(taskId: bigint): Promise<bigint[]> {
    return this.call('getReviewsByTask', [taskId]);
  }

  async getReviewsByReviewee(reviewee: EthereumAddress): Promise<bigint[]> {
    return this.call('getReviewsByReviewee', [reviewee]);
  }

  async getAverageRating(reviewee: EthereumAddress): Promise<{ average: bigint; count: bigint }> {
    return this.call('getAverageRating', [reviewee]);
  }
}

export class TaskDispute extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, TaskDisputeABI, provider);
  }

  async initiateDispute(
    taskId: bigint,
    reasonHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('initiateDispute', [taskId, reasonHash], overrides);
  }

  async respondToDispute(
    disputeId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('respondToDispute', [disputeId], overrides);
  }

  async resolveTaskDispute(
    disputeId: bigint,
    outcome: number,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('resolveTaskDispute', [disputeId, outcome], overrides);
  }

  async getTaskDispute(disputeId: bigint): Promise<TaskDisputeRecord> {
    const result = await this.call<any>('getTaskDispute', [disputeId]);
    return {
      disputeId: result.disputeId,
      taskId: result.taskId,
      initiator: result.initiator,
      respondent: result.respondent,
      initiatedAt: result.initiatedAt,
      status: result.status,
      outcome: result.outcome,
      reasonHash: result.reasonHash,
    };
  }

  async getDisputesByTask(taskId: bigint): Promise<bigint[]> {
    return this.call('getDisputesByTask', [taskId]);
  }
}
