import { ethers } from 'ethers';
import {
  CovenantSDKError,
  ContractCallError,
  TransactionError,
  ValidationError,
  EthereumAddress,
} from '../types';

export function validateAddress(address: string): EthereumAddress {
  if (!ethers.isAddress(address)) {
    throw new ValidationError(`Invalid Ethereum address: ${address}`);
  }
  return address.toLowerCase() as EthereumAddress;
}

export function validateBytes32(value: string): string {
  if (!/^0x([0-9a-fA-F]{64})$/.test(value)) {
    throw new ValidationError(`Invalid bytes32 value: ${value}`);
  }
  return value.toLowerCase();
}

export function isValidAddress(address: string): boolean {
  return ethers.isAddress(address);
}

export function toBytes32(value: string): string {
  return ethers.encodeBytes32String(value);
}

export function fromBytes32(value: string): string {
  return ethers.decodeBytes32String(value);
}

export function keccak256(value: string): string {
  return ethers.keccak256(ethers.toUtf8Bytes(value));
}

export function parseEther(value: string): bigint {
  try {
    return ethers.parseEther(value);
  } catch (err) {
    throw new ValidationError(`Failed to parse ether: ${value}`, err as Error);
  }
}

export function formatEther(value: bigint): string {
  return ethers.formatEther(value);
}

export function parseUnits(value: string, decimals: number): bigint {
  try {
    return ethers.parseUnits(value, decimals);
  } catch (err) {
    throw new ValidationError(`Failed to parse units: ${value}`, err as Error);
  }
}

export function formatUnits(value: bigint, decimals: number): string {
  return ethers.formatUnits(value, decimals);
}

export async function handleContractCall<T>(
  fn: () => Promise<T>,
  operation: string
): Promise<T> {
  try {
    return await fn();
  } catch (err: any) {
    const message = err?.reason || err?.message || 'Unknown contract error';
    if (err?.code === 'INSUFFICIENT_FUNDS') {
      throw new ContractCallError(`Insufficient funds for ${operation}: ${message}`, err);
    }
    if (err?.code === 'CALL_EXCEPTION') {
      throw new ContractCallError(`Call failed for ${operation}: ${message}`, err);
    }
    if (err?.code === 'NONCE_EXPIRED' || err?.code === 'REPLACEMENT_UNDERPRICED') {
      throw new TransactionError(`Transaction error for ${operation}: ${message}`, err);
    }
    throw new ContractCallError(`${operation} failed: ${message}`, err);
  }
}

export async function handleTransaction<T>(
  fn: () => Promise<T>,
  operation: string
): Promise<T> {
  try {
    return await fn();
  } catch (err: any) {
    const message = err?.reason || err?.message || 'Unknown transaction error';
    throw new TransactionError(`${operation} failed: ${message}`, err);
  }
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function retry<T>(
  fn: () => Promise<T>,
  retries: number = 3,
  delay: number = 1000
): Promise<T> {
  let lastError: Error | undefined;
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err as Error;
      if (i < retries - 1) {
        await sleep(delay * Math.pow(2, i));
      }
    }
  }
  throw lastError;
}

export function encodeInitializeData(
  creator: string,
  covenantId: bigint,
  params: string
): string {
  const iface = new ethers.Interface([
    'function initialize(address creator, uint256 covenantId, bytes params)',
  ]);
  return iface.encodeFunctionData('initialize', [creator, covenantId, params]);
}

export function encodeFunctionCall(
  signature: string,
  values: any[]
): string {
  const iface = new ethers.Interface([signature]);
  const frag = iface.getFunction(signature);
  if (!frag) throw new ValidationError(`Invalid function signature: ${signature}`);
  return iface.encodeFunctionData(frag, values);
}

export function getEventTopics(
  abi: any[],
  eventName: string
): string[] | undefined {
  const iface = new ethers.Interface(abi);
  const event = iface.getEvent(eventName);
  if (!event) return undefined;
  return [event.topicHash];
}
