import * as fsExtra from 'fs-extra';
import * as path from 'path';
import { ethers, Wallet as EthersWallet, HDNodeWallet } from 'ethers';
import inquirer from 'inquirer';
import { getWalletsDir, loadConfig, saveConfig } from './config.js';
import { logger } from './logger.js';

const { existsSync, writeJsonSync, readJsonSync, removeSync, readdirSync, ensureDirSync } = fsExtra as any;

export interface WalletData {
  name: string;
  address: string;
  encryptedPrivateKey: string;
  createdAt: string;
}

export function listWallets(): WalletData[] {
  const walletsDir = getWalletsDir();
  if (!existsSync(walletsDir)) return [];
  
  const wallets: WalletData[] = [];
  const files = readdirSync(walletsDir).filter((f: string) => f.endsWith('.json'));
  
  for (const file of files) {
    try {
      const data = readJsonSync(path.join(walletsDir, file));
      wallets.push(data);
    } catch {
      // Skip invalid files
    }
  }
  return wallets;
}

export function getWalletPath(name: string): string {
  return path.join(getWalletsDir(), `${name}.json`);
}

export function loadWalletData(name: string): WalletData | null {
  const walletPath = getWalletPath(name);
  if (!existsSync(walletPath)) return null;
  return readJsonSync(walletPath);
}

export async function createWallet(name: string, password?: string): Promise<WalletData> {
  const walletsDir = getWalletsDir();
  ensureDirSync(walletsDir);
  
  const existing = loadWalletData(name);
  if (existing) {
    throw new Error(`Wallet "${name}" already exists.`);
  }
  
  const wallet: HDNodeWallet = ethers.Wallet.createRandom();
  
  let finalPassword = password;
  if (!finalPassword) {
    const answers = await inquirer.prompt([{
      type: 'password',
      name: 'password',
      message: 'Set wallet password:',
      mask: '*',
      validate: (input: string) => input.length >= 8 || 'Password must be at least 8 characters'
    }, {
      type: 'password',
      name: 'confirmPassword',
      message: 'Confirm password:',
      mask: '*'
    }]);
    
    if (answers.password !== answers.confirmPassword) {
      throw new Error('Passwords do not match.');
    }
    finalPassword = answers.password;
  }
  
  const encryptedPrivateKey = await wallet.encrypt(finalPassword!);
  
  const walletData: WalletData = {
    name,
    address: wallet.address,
    encryptedPrivateKey,
    createdAt: new Date().toISOString()
  };
  
  writeJsonSync(getWalletPath(name), walletData, { spaces: 2 });
  
  const config = loadConfig();
  if (!config.defaultWallet) {
    config.defaultWallet = name;
    saveConfig(config);
  }
  
  return walletData;
}

export async function importWallet(name: string, privateKey: string, password?: string): Promise<WalletData> {
  const walletsDir = getWalletsDir();
  ensureDirSync(walletsDir);
  
  const existing = loadWalletData(name);
  if (existing) {
    throw new Error(`Wallet "${name}" already exists.`);
  }
  
  // Normalize private key
  privateKey = privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`;
  
  let wallet: ethers.Wallet;
  try {
    wallet = new ethers.Wallet(privateKey);
  } catch (err) {
    throw new Error(`Invalid private key: ${(err as Error).message}`);
  }
  
  let finalPassword = password;
  if (!finalPassword) {
    const answers = await inquirer.prompt([{
      type: 'password',
      name: 'password',
      message: 'Set wallet password:',
      mask: '*',
      validate: (input: string) => input.length >= 8 || 'Password must be at least 8 characters'
    }]);
    finalPassword = answers.password;
  }
  
  const encryptedPrivateKey = await wallet.encrypt(finalPassword!);
  
  const walletData: WalletData = {
    name,
    address: wallet.address,
    encryptedPrivateKey,
    createdAt: new Date().toISOString()
  };
  
  writeJsonSync(getWalletPath(name), walletData, { spaces: 2 });
  
  return walletData;
}

export async function unlockWallet(name: string, password?: string): Promise<EthersWallet | HDNodeWallet> {
  const walletData = loadWalletData(name);
  if (!walletData) {
    throw new Error(`Wallet "${name}" not found.`);
  }
  
  if (!password) {
    const answers = await inquirer.prompt([{
      type: 'password',
      name: 'password',
      message: `Enter password for wallet "${name}":`,
      mask: '*'
    }]);
    password = answers.password;
  }
  
  try {
    const wallet = await ethers.Wallet.fromEncryptedJson(walletData.encryptedPrivateKey, password!);
    logger.debug(`Wallet "${name}" (${wallet.address}) unlocked`);
    return wallet;
  } catch (err) {
    throw new Error(`Failed to unlock wallet: ${(err as Error).message}`);
  }
}

export async function getWallet(name?: string, password?: string, provider?: ethers.Provider): Promise<EthersWallet | HDNodeWallet> {
  const config = loadConfig();
  const walletName = name || config.defaultWallet;
  
  if (!walletName) {
    const wallets = listWallets();
    if (wallets.length === 0) {
      throw new Error('No wallets found. Create one with "covenant wallet create".');
    }
    const answers = await inquirer.prompt([{
      type: 'list',
      name: 'wallet',
      message: 'Select wallet:',
      choices: wallets.map(w => ({ name: `${w.name} (${w.address})`, value: w.name }))
    }]);
    return unlockWallet(answers.wallet, password);
  }
  
  const wallet = await unlockWallet(walletName, password);
  return provider ? wallet.connect(provider) : wallet;
}

export function deleteWallet(name: string): void {
  const walletPath = getWalletPath(name);
  if (!existsSync(walletPath)) {
    throw new Error(`Wallet "${name}" not found.`);
  }
  removeSync(walletPath);
  
  const config = loadConfig();
  if (config.defaultWallet === name) {
    config.defaultWallet = undefined;
    saveConfig(config);
  }
}

export function setDefaultWallet(name: string): void {
  const walletData = loadWalletData(name);
  if (!walletData) {
    throw new Error(`Wallet "${name}" not found.`);
  }
  const config = loadConfig();
  config.defaultWallet = name;
  saveConfig(config);
}
