import * as os from 'os';
import * as path from 'path';
import { existsSync } from 'fs';
import * as fsExtra from 'fs-extra';
import { z } from 'zod';

const { ensureDirSync, writeJsonSync, readJsonSync } = fsExtra as any;

const CONFIG_DIR = path.join(os.homedir(), '.covenant');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');
const WALLETS_DIR = path.join(CONFIG_DIR, 'wallets');

const NetworkSchema = z.object({
  name: z.string(),
  rpcUrl: z.string().url(),
  chainId: z.number().int().positive(),
  explorer: z.string().url().optional(),
  contracts: z.record(z.string()).default({})
});

const ConfigSchema = z.object({
  version: z.string().default('1.0.0'),
  defaultNetwork: z.string().default('mainnet'),
  defaultWallet: z.string().optional(),
  logLevel: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  dryRun: z.boolean().default(false),
  autoConfirm: z.boolean().default(false),
  gasMultiplier: z.number().default(1.2),
  networks: z.array(NetworkSchema).default([])
});

export type Config = z.infer<typeof ConfigSchema>;
export type NetworkConfig = z.infer<typeof NetworkSchema>;

const defaultNetworks: NetworkConfig[] = [
  {
    name: 'mainnet',
    rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY',
    chainId: 1,
    explorer: 'https://etherscan.io',
    contracts: {}
  },
  {
    name: 'sepolia',
    rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY',
    chainId: 11155111,
    explorer: 'https://sepolia.etherscan.io',
    contracts: {}
  },
  {
    name: 'polygon',
    rpcUrl: 'https://polygon-mainnet.g.alchemy.com/v2/YOUR_API_KEY',
    chainId: 137,
    explorer: 'https://polygonscan.com',
    contracts: {}
  },
  {
    name: 'localhost',
    rpcUrl: 'http://127.0.0.1:8545',
    chainId: 31337,
    contracts: {}
  }
];

export function ensureConfigDir(): void {
  ensureDirSync(CONFIG_DIR);
  ensureDirSync(WALLETS_DIR);
}

export function getConfigPath(): string {
  return CONFIG_FILE;
}

export function getWalletsDir(): string {
  return WALLETS_DIR;
}

export function loadConfig(): Config {
  ensureConfigDir();
  if (!existsSync(CONFIG_FILE)) {
    const defaultConfig: Config = {
      version: '1.0.0',
      defaultNetwork: 'sepolia',
      networks: defaultNetworks,
      logLevel: 'info',
      dryRun: false,
      autoConfirm: false,
      gasMultiplier: 1.2
    };
    saveConfig(defaultConfig);
    return defaultConfig;
  }
  const raw = readJsonSync(CONFIG_FILE);
  return ConfigSchema.parse(raw);
}

export function saveConfig(config: Config): void {
  ensureConfigDir();
  writeJsonSync(CONFIG_FILE, config, { spaces: 2 });
}

export function getNetwork(config: Config, name?: string): NetworkConfig {
  const netName = name || config.defaultNetwork;
  const network = config.networks.find(n => n.name === netName);
  if (!network) {
    throw new Error(`Network "${netName}" not found. Run "covenant network list" to see available networks.`);
  }
  return network;
}

export function setDefaultNetwork(config: Config, name: string): void {
  const network = config.networks.find(n => n.name === name);
  if (!network) {
    throw new Error(`Network "${name}" not found.`);
  }
  config.defaultNetwork = name;
  saveConfig(config);
}

export function addNetwork(config: Config, network: NetworkConfig): void {
  const existingIndex = config.networks.findIndex(n => n.name === network.name);
  if (existingIndex >= 0) {
    config.networks[existingIndex] = network;
  } else {
    config.networks.push(network);
  }
  saveConfig(config);
}

export function removeNetwork(config: Config, name: string): void {
  if (name === config.defaultNetwork) {
    throw new Error(`Cannot remove the default network. Switch default first.`);
  }
  config.networks = config.networks.filter(n => n.name !== name);
  saveConfig(config);
}
