import { ethers } from 'ethers';
import type { NetworkConfig } from './config.js';
import { logger } from './logger.js';

export async function getProvider(network: NetworkConfig): Promise<ethers.JsonRpcProvider> {
  const provider = new ethers.JsonRpcProvider(network.rpcUrl);
  try {
    const networkInfo = await provider.getNetwork();
    logger.debug(`Connected to ${network.name} (chainId: ${networkInfo.chainId})`);
    return provider;
  } catch (err) {
    throw new Error(`Failed to connect to ${network.name} at ${network.rpcUrl}: ${(err as Error).message}`);
  }
}

export async function validateNetwork(provider: ethers.Provider, expectedChainId: number): Promise<void> {
  const network = await provider.getNetwork();
  if (network.chainId !== BigInt(expectedChainId)) {
    throw new Error(
      `Chain ID mismatch. Expected ${expectedChainId}, got ${network.chainId}. Please check your RPC URL.`
    );
  }
}

export async function getGasPrice(provider: ethers.Provider): Promise<bigint> {
  const feeData = await provider.getFeeData();
  return feeData.gasPrice || 0n;
}

export async function getBlockNumber(provider: ethers.Provider): Promise<number> {
  return provider.getBlockNumber();
}

export async function getBalance(provider: ethers.Provider, address: string): Promise<string> {
  const balance = await provider.getBalance(address);
  return ethers.formatEther(balance);
}

export function formatExplorerUrl(network: NetworkConfig, path: string): string | undefined {
  if (!network.explorer) return undefined;
  return `${network.explorer}${path}`;
}
