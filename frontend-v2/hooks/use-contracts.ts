'use client';

import { useReadContract, useReadContracts, useWriteContract, useAccount, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther, type Address } from 'viem';
import { CONTRACTS, CHAIN_ID } from '@/lib/contracts';

// ─── Protocol Stats (read-only, no wallet needed) ───────────────────────────

export function useProtocolStats() {
  const results = useReadContracts({
    contracts: [
      {
        ...CONTRACTS.AgentRegistry,
        functionName: 'totalAgents',
      },
      {
        ...CONTRACTS.CovenantFactory,
        functionName: 'getCovenantCount',
      },
      {
        ...CONTRACTS.TaskMarket,
        functionName: 'totalTasksPosted',
      },
      {
        ...CONTRACTS.TaskMarket,
        functionName: 'totalTasksCompleted',
      },
      {
        ...CONTRACTS.TaskMarket,
        functionName: 'totalValueLocked',
      },
      {
        ...CONTRACTS.TaskMarket,
        functionName: 'nextTaskId',
      },
      {
        ...CONTRACTS.ReputationStake,
        functionName: 'totalStaked',
      },
      {
        ...CONTRACTS.ReputationStake,
        functionName: 'totalAgents',
      },
      {
        ...CONTRACTS.DisputeDAO,
        functionName: 'nextDisputeId',
      },
    ],
  });

  const data = results.data;

  return {
    isLoading: results.isLoading,
    error: results.error,
    refetch: results.refetch,
    totalAgents: data?.[0]?.result as bigint | undefined,
    totalCovenants: data?.[1]?.result as bigint | undefined,
    totalTasksPosted: data?.[2]?.result as bigint | undefined,
    totalTasksCompleted: data?.[3]?.result as bigint | undefined,
    totalValueLocked: data?.[4]?.result as bigint | undefined,
    nextTaskId: data?.[5]?.result as bigint | undefined,
    totalStaked: data?.[6]?.result as bigint | undefined,
    stakedAgents: data?.[7]?.result as bigint | undefined,
    nextDisputeId: data?.[8]?.result as bigint | undefined,
  };
}

// ─── Agent Registry ─────────────────────────────────────────────────────────

export function useAgentProfile(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.AgentRegistry,
    functionName: 'getAgent',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    agent: result.data as any,
    isLoading: result.isLoading,
    error: result.error,
    refetch: result.refetch,
  };
}

export function useIsRegistered(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.AgentRegistry,
    functionName: 'isRegistered',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    isRegistered: result.data as boolean | undefined,
    isLoading: result.isLoading,
  };
}

export function useRegistrationFee() {
  const result = useReadContract({
    ...CONTRACTS.AgentRegistry,
    functionName: 'REGISTRATION_FEE',
  });

  return result.data as bigint | undefined;
}

export function useRegisterAgent() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const register = (metadataURI: string, skillIds: bigint[], fee: bigint) => {
    writeContract({
      ...CONTRACTS.AgentRegistry,
      functionName: 'registerAgent',
      args: [metadataURI, skillIds],
      value: fee,
    });
  };

  return { register, hash, isPending, isConfirming, isSuccess, error };
}

// ─── Task Market ────────────────────────────────────────────────────────────

export function useOpenTasks(offset: bigint = 0n, limit: bigint = 50n) {
  const result = useReadContract({
    ...CONTRACTS.TaskMarket,
    functionName: 'getOpenTasks',
    args: [offset, limit],
  });

  return {
    taskIds: result.data as bigint[] | undefined,
    isLoading: result.isLoading,
    error: result.error,
    refetch: result.refetch,
  };
}

export function useTask(taskId: bigint) {
  const result = useReadContract({
    ...CONTRACTS.TaskMarket,
    functionName: 'getTask',
    args: [taskId],
    query: { enabled: taskId >= 0n },
  });

  return {
    task: result.data as any,
    isLoading: result.isLoading,
    error: result.error,
  };
}

export function useTaskBids(taskId: bigint) {
  const result = useReadContract({
    ...CONTRACTS.TaskMarket,
    functionName: 'getBids',
    args: [taskId],
  });

  return {
    bids: result.data as any[] | undefined,
    isLoading: result.isLoading,
  };
}

export function useAgentStats(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.TaskMarket,
    functionName: 'getAgentStats',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    stats: result.data as [bigint, bigint, bigint] | undefined,
    isLoading: result.isLoading,
  };
}

export function usePostTask() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const postTask = (
    title: string,
    description: string,
    requiredSkills: string,
    deadline: bigint,
    priority: number,
    reward: bigint,
  ) => {
    writeContract({
      ...CONTRACTS.TaskMarket,
      functionName: 'postTask',
      args: [title, description, requiredSkills, deadline, priority],
      value: reward,
    });
  };

  return { postTask, hash, isPending, isConfirming, isSuccess, error };
}

export function useBidOnTask() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const bid = (taskId: bigint, amount: bigint, estimatedTime: bigint, proposal: string) => {
    writeContract({
      ...CONTRACTS.TaskMarket,
      functionName: 'bidOnTask',
      args: [taskId, amount, estimatedTime, proposal],
    });
  };

  return { bid, hash, isPending, isConfirming, isSuccess, error };
}

export function useAcceptBid() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const acceptBid = (taskId: bigint, bidIndex: bigint) => {
    writeContract({
      ...CONTRACTS.TaskMarket,
      functionName: 'acceptBid',
      args: [taskId, bidIndex],
    });
  };

  return { acceptBid, hash, isPending, isConfirming, isSuccess, error };
}

export function useApproveWork() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const approveWork = (taskId: bigint) => {
    writeContract({
      ...CONTRACTS.TaskMarket,
      functionName: 'approveWork',
      args: [taskId],
    });
  };

  return { approveWork, hash, isPending, isConfirming, isSuccess, error };
}

export function useSubmitWork() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const submitWork = (taskId: bigint, proofURI: string) => {
    writeContract({
      ...CONTRACTS.TaskMarket,
      functionName: 'submitWork',
      args: [taskId, proofURI],
    });
  };

  return { submitWork, hash, isPending, isConfirming, isSuccess, error };
}

// ─── Covenant Factory ───────────────────────────────────────────────────────

export function useCreateCovenant() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const createCovenant = (
    counterparty: Address,
    covenantType: `0x${string}`,
    metadataURI: string,
    duration: bigint,
    stakeAmount: bigint,
  ) => {
    writeContract({
      ...CONTRACTS.CovenantFactory,
      functionName: 'createCovenant',
      args: [counterparty, covenantType, metadataURI, duration],
      value: stakeAmount,
    });
  };

  return { createCovenant, hash, isPending, isConfirming, isSuccess, error };
}

export function useCovenantList(offset: bigint = 0n, limit: bigint = 50n) {
  const result = useReadContract({
    ...CONTRACTS.CovenantFactory,
    functionName: 'getCovenants',
    args: [offset, limit],
  });

  return {
    covenantAddresses: result.data as Address[] | undefined,
    isLoading: result.isLoading,
    error: result.error,
    refetch: result.refetch,
  };
}

// ─── Reputation & Staking ───────────────────────────────────────────────────

export function useReputationProfile(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.ReputationStake,
    functionName: 'getAgentProfile',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    profile: result.data as any,
    isLoading: result.isLoading,
    error: result.error,
    refetch: result.refetch,
  };
}

export function useReputationScore(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.ReputationStake,
    functionName: 'calculateReputation',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    score: result.data as bigint | undefined,
    isLoading: result.isLoading,
  };
}

export function useStake() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const stake = (amount: bigint) => {
    writeContract({
      ...CONTRACTS.ReputationStake,
      functionName: 'stake',
      args: [amount],
    });
  };

  return { stake, hash, isPending, isConfirming, isSuccess, error };
}

export function useWithdrawStake() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const withdraw = (stakeIndex: bigint) => {
    writeContract({
      ...CONTRACTS.ReputationStake,
      functionName: 'withdrawStake',
      args: [stakeIndex],
    });
  };

  return { withdraw, hash, isPending, isConfirming, isSuccess, error };
}

// ─── Stake Token (ERC20) ────────────────────────────────────────────────────

export function useTokenBalance(address?: Address) {
  const result = useReadContract({
    ...CONTRACTS.StakeToken,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  return {
    balance: result.data as bigint | undefined,
    isLoading: result.isLoading,
    refetch: result.refetch,
  };
}

export function useTokenApprove() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const approve = (spender: Address, amount: bigint) => {
    writeContract({
      ...CONTRACTS.StakeToken,
      functionName: 'approve',
      args: [spender, amount],
    });
  };

  return { approve, hash, isPending, isConfirming, isSuccess, error };
}

export function useFaucet() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const claimFaucet = () => {
    writeContract({
      ...CONTRACTS.StakeToken,
      functionName: 'faucet',
    });
  };

  return { claimFaucet, hash, isPending, isConfirming, isSuccess, error };
}

// ─── Dispute DAO ────────────────────────────────────────────────────────────

export function useCreateDispute() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const createDispute = (covenant: Address, reason: string, evidence: string, fee: bigint) => {
    writeContract({
      ...CONTRACTS.DisputeDAO,
      functionName: 'createDispute',
      args: [covenant, reason, evidence],
      value: fee,
    });
  };

  return { createDispute, hash, isPending, isConfirming, isSuccess, error };
}

export function useDisputeInfo(disputeId: bigint) {
  const result = useReadContract({
    ...CONTRACTS.DisputeDAO,
    functionName: 'getDispute',
    args: [disputeId],
    query: { enabled: disputeId >= 0n },
  });

  return {
    dispute: result.data as any,
    isLoading: result.isLoading,
  };
}

export function useRegisterJuror() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const registerAsJuror = (stakeAmount: bigint) => {
    writeContract({
      ...CONTRACTS.DisputeDAO,
      functionName: 'registerAsJuror',
      args: [stakeAmount],
    });
  };

  return { registerAsJuror, hash, isPending, isConfirming, isSuccess, error };
}

// ─── Helpers ────────────────────────────────────────────────────────────────

export { formatEther, parseEther };
