import { ethers } from 'ethers';
import { logger } from './logger.js';

export interface GasEstimate {
  gasLimit: bigint;
  gasPrice: bigint;
  maxFeePerGas?: bigint;
  maxPriorityFeePerGas?: bigint;
  estimatedCost: bigint;
  estimatedCostEth: string;
}

export async function estimateGas(
  provider: ethers.Provider,
  transaction: ethers.TransactionRequest,
  multiplier: number = 1.2
): Promise<GasEstimate> {
  const feeData = await provider.getFeeData();
  
  let gasLimit: bigint;
  try {
    gasLimit = await provider.estimateGas(transaction);
    // Apply safety margin
    gasLimit = (gasLimit * BigInt(Math.round(multiplier * 100))) / 100n;
  } catch (err) {
    logger.warn(`Gas estimation failed: ${(err as Error).message}`);
    gasLimit = 300000n; // Default fallback
  }
  
  let gasPrice: bigint;
  let maxFeePerGas: bigint | undefined;
  let maxPriorityFeePerGas: bigint | undefined;
  
  if (feeData.maxFeePerGas && feeData.maxPriorityFeePerGas) {
    // EIP-1559
    maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;
    maxFeePerGas = feeData.maxFeePerGas;
    gasPrice = maxFeePerGas;
  } else {
    // Legacy
    gasPrice = feeData.gasPrice || 0n;
  }
  
  const estimatedCost = gasLimit * gasPrice;
  
  return {
    gasLimit,
    gasPrice,
    maxFeePerGas,
    maxPriorityFeePerGas,
    estimatedCost,
    estimatedCostEth: ethers.formatEther(estimatedCost)
  };
}

export function formatGasEstimate(estimate: GasEstimate): string {
  const lines = [
    `Gas Limit: ${estimate.gasLimit.toString()}`,
    `Gas Price: ${ethers.formatUnits(estimate.gasPrice, 'gwei')} gwei`,
  ];
  
  if (estimate.maxFeePerGas) {
    lines.push(`Max Fee: ${ethers.formatUnits(estimate.maxFeePerGas, 'gwei')} gwei`);
  }
  if (estimate.maxPriorityFeePerGas) {
    lines.push(`Priority Fee: ${ethers.formatUnits(estimate.maxPriorityFeePerGas, 'gwei')} gwei`);
  }
  
  lines.push(`Est. Cost: ${estimate.estimatedCostEth} ETH`);
  
  return lines.join('\n');
}

export async function checkBalance(
  provider: ethers.Provider,
  address: string,
  requiredAmount?: bigint
): Promise<void> {
  const balance = await provider.getBalance(address);
  
  logger.debug(`Balance check for ${address}: ${ethers.formatEther(balance)} ETH`);
  
  if (requiredAmount && balance < requiredAmount) {
    throw new Error(
      `Insufficient balance. Required: ${ethers.formatEther(requiredAmount)} ETH, ` +
      `Available: ${ethers.formatEther(balance)} ETH`
    );
  }
}
