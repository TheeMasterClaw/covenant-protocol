/**
 * COVENANT Protocol - OnchainOS Integration Module
 *
 * Integrates OKX OnchainOS skills for:
 * - Agentic Wallet creation and management
 * - DEX aggregation swaps (OnchainOS DEX skill)
 * - Wallet balance queries (OnchainOS Wallet skill)
 * - x402 payment protocol for agent service payments
 *
 * OnchainOS Docs: https://www.okx.com/web3/build/docs/devportal/introduction-to-onchain-os
 */

const { ethers } = require('ethers');
const axios = require('axios');

// OnchainOS API configuration
const ONCHAINOS_BASE_URL = 'https://www.okx.com/api/v5';
const XLAYER_CHAIN_ID = '196'; // X Layer Mainnet
const XLAYER_TESTNET_CHAIN_ID = '1952';

class OnchainOSIntegration {
  constructor({ apiKey, secretKey, passphrase, chainId = XLAYER_CHAIN_ID }) {
    this.apiKey = apiKey;
    this.secretKey = secretKey;
    this.passphrase = passphrase;
    this.chainId = chainId;
    this.baseUrl = ONCHAINOS_BASE_URL;
  }

  /**
   * Generate authentication headers for OnchainOS API
   */
  _getHeaders(timestamp, method, path, body = '') {
    const crypto = require('crypto');
    const preSign = timestamp + method.toUpperCase() + path + body;
    const signature = crypto
      .createHmac('sha256', this.secretKey)
      .update(preSign)
      .digest('base64');

    return {
      'OK-ACCESS-KEY': this.apiKey,
      'OK-ACCESS-SIGN': signature,
      'OK-ACCESS-TIMESTAMP': timestamp,
      'OK-ACCESS-PASSPHRASE': this.passphrase,
      'Content-Type': 'application/json',
    };
  }

  // ========== Agentic Wallet Skill ==========

  /**
   * Create an Agentic Wallet for a COVENANT agent.
   * This wallet serves as the agent's on-chain identity.
   *
   * @param {string} agentName - Human-readable agent identifier
   * @returns {Object} Wallet address and metadata
   */
  async createAgenticWallet(agentName) {
    console.log(`Creating Agentic Wallet for agent: ${agentName}`);

    // Generate a new wallet keypair for the agent
    const wallet = ethers.Wallet.createRandom();

    return {
      address: wallet.address,
      agentName,
      chainId: this.chainId,
      createdAt: new Date().toISOString(),
      // The private key should be stored securely by the agent
      // In production, use a TEE or hardware security module
      _privateKey: wallet.privateKey,
    };
  }

  /**
   * Register an Agentic Wallet with the COVENANT AgentRegistry.
   *
   * @param {Object} wallet - Wallet from createAgenticWallet
   * @param {string} registryAddress - AgentRegistry contract address
   * @param {string} metadataURI - IPFS URI with agent profile
   * @param {number[]} skillIds - Array of skill IDs to register
   * @param {string} rpcUrl - X Layer RPC endpoint
   */
  async registerWalletAsAgent(wallet, registryAddress, metadataURI, skillIds, rpcUrl) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(wallet._privateKey, provider);

    const registryAbi = [
      'function registerAgent(string calldata _metadataURI, uint256[] calldata _skillIds) external payable',
      'function getAgent(address _agent) external view returns (tuple(address agentAddress, string metadataURI, uint256[] skills, string[] skillNames, uint256 reputationScore, bool isActive, uint256 registeredAt, uint256 lastActive, uint256 covenantsCompleted, uint256 tasksCompleted, uint256 totalEarned))',
    ];

    const registry = new ethers.Contract(registryAddress, registryAbi, signer);

    const tx = await registry.registerAgent(metadataURI, skillIds, {
      value: ethers.parseEther('0.001'), // Registration fee
    });

    const receipt = await tx.wait();
    console.log(`Agent registered on-chain. TX: ${receipt.hash}`);

    return {
      txHash: receipt.hash,
      agentAddress: wallet.address,
      registryAddress,
      skillIds,
    };
  }

  // ========== OnchainOS DEX Skill ==========

  /**
   * Execute a token swap using OnchainOS DEX aggregation.
   * Agents use this to convert earned tokens (e.g., COV -> OKB).
   *
   * @param {string} fromToken - Source token contract address
   * @param {string} toToken - Destination token contract address
   * @param {string} amount - Amount in base units
   * @param {string} userAddress - Agent wallet address
   * @param {number} slippage - Slippage tolerance (e.g., 0.5 for 0.5%)
   * @returns {Object} Swap quote and transaction data
   */
  async getSwapQuote(fromToken, toToken, amount, userAddress, slippage = 0.5) {
    const timestamp = new Date().toISOString();
    const path = `/dex/aggregator/swap?chainId=${this.chainId}&fromTokenAddress=${fromToken}&toTokenAddress=${toToken}&amount=${amount}&userWalletAddress=${userAddress}&slippage=${slippage}`;

    const headers = this._getHeaders(timestamp, 'GET', path);

    const response = await axios.get(`${this.baseUrl}${path}`, { headers });

    return response.data;
  }

  /**
   * Get the best swap route across DEXes on X Layer.
   *
   * @param {string} fromToken - Source token address
   * @param {string} toToken - Destination token address
   * @param {string} amount - Amount in base units
   * @returns {Object} Route information with price impact
   */
  async getSwapRoute(fromToken, toToken, amount) {
    const timestamp = new Date().toISOString();
    const path = `/dex/aggregator/quote?chainId=${this.chainId}&fromTokenAddress=${fromToken}&toTokenAddress=${toToken}&amount=${amount}`;

    const headers = this._getHeaders(timestamp, 'GET', path);

    const response = await axios.get(`${this.baseUrl}${path}`, { headers });

    return response.data;
  }

  /**
   * Execute a swap transaction for an agent.
   *
   * @param {Object} swapData - Swap data from getSwapQuote
   * @param {string} privateKey - Agent wallet private key
   * @param {string} rpcUrl - X Layer RPC URL
   */
  async executeSwap(swapData, privateKey, rpcUrl) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const signer = new ethers.Wallet(privateKey, provider);

    const txData = swapData.data[0].tx;
    const tx = await signer.sendTransaction({
      to: txData.to,
      data: txData.data,
      value: txData.value || '0x0',
      gasLimit: txData.gas,
    });

    const receipt = await tx.wait();
    console.log(`Swap executed. TX: ${receipt.hash}`);
    return receipt;
  }

  // ========== OnchainOS Wallet Skill ==========

  /**
   * Query agent wallet balances using OnchainOS Wallet skill.
   *
   * @param {string} address - Agent wallet address
   * @returns {Object} Token balances for the wallet
   */
  async getWalletBalances(address) {
    const timestamp = new Date().toISOString();
    const path = `/wallet/asset/token-balances?chainIndex=${this.chainId}&address=${address}`;

    const headers = this._getHeaders(timestamp, 'GET', path);

    const response = await axios.get(`${this.baseUrl}${path}`, { headers });

    return response.data;
  }

  /**
   * Get transaction history for an agent wallet.
   *
   * @param {string} address - Agent wallet address
   * @param {number} limit - Number of transactions to return
   * @returns {Object} Transaction history
   */
  async getTransactionHistory(address, limit = 20) {
    const timestamp = new Date().toISOString();
    const path = `/wallet/asset/transactions?chainIndex=${this.chainId}&address=${address}&limit=${limit}`;

    const headers = this._getHeaders(timestamp, 'GET', path);

    const response = await axios.get(`${this.baseUrl}${path}`, { headers });

    return response.data;
  }

  // ========== x402 Payment Skill ==========

  /**
   * Create an x402 payment request for an agent service.
   * Enables pay-per-call access to agent skills in the COVENANT marketplace.
   *
   * @param {string} agentAddress - Service provider agent address
   * @param {string} amount - Payment amount in wei
   * @param {string} serviceDescription - Description of the service
   * @returns {Object} x402 payment envelope
   */
  createX402PaymentRequest(agentAddress, amount, serviceDescription) {
    return {
      version: '1',
      network: `xlayer:${this.chainId}`,
      payTo: agentAddress,
      maxAmountRequired: amount,
      asset: 'native', // OKB on X Layer
      description: serviceDescription,
      resource: `covenant://agent/${agentAddress}/service`,
      createdAt: new Date().toISOString(),
    };
  }

  /**
   * Verify an x402 payment receipt.
   *
   * @param {Object} receipt - x402 payment receipt
   * @param {string} rpcUrl - RPC URL to verify on-chain
   * @returns {boolean} Whether the payment is valid
   */
  async verifyX402Payment(receipt, rpcUrl) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const tx = await provider.getTransactionReceipt(receipt.txHash);

    if (!tx) return false;

    return (
      tx.status === 1 &&
      tx.to.toLowerCase() === receipt.payTo.toLowerCase()
    );
  }
}

// ========== Demo: Full Agent Lifecycle with OnchainOS ==========

async function demo() {
  const XLAYER_TESTNET_RPC = 'https://testrpc.xlayer.tech';
  const REGISTRY_ADDRESS = '0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA';

  if (!process.env.OKX_API_KEY) {
    console.log('NOTE: Set OKX_API_KEY, OKX_SECRET_KEY, OKX_PASSPHRASE in .env for live API calls.\n');
  }

  const os = new OnchainOSIntegration({
    apiKey: process.env.OKX_API_KEY || '',
    secretKey: process.env.OKX_SECRET_KEY || '',
    passphrase: process.env.OKX_PASSPHRASE || '',
    chainId: XLAYER_TESTNET_CHAIN_ID,
  });

  console.log('=== COVENANT x OnchainOS Integration Demo ===\n');

  // Step 1: Create Agentic Wallet
  console.log('1. Creating Agentic Wallet...');
  const wallet = await os.createAgenticWallet('Disciple-Alpha');
  console.log(`   Wallet: ${wallet.address}\n`);

  // Step 2: Create x402 payment request
  console.log('2. Creating x402 payment request...');
  const payment = os.createX402PaymentRequest(
    wallet.address,
    ethers.parseEther('0.01').toString(),
    'Data analysis task completion'
  );
  console.log(`   Payment resource: ${payment.resource}\n`);

  // Step 3: Query wallet balances (requires funded API key)
  console.log('3. Wallet balance query ready');
  console.log(`   Endpoint: /wallet/asset/token-balances?chainIndex=${os.chainId}&address=${wallet.address}\n`);

  // Step 4: DEX swap route (requires funded API key)
  console.log('4. DEX swap route ready');
  console.log(`   Endpoint: /dex/aggregator/quote?chainId=${os.chainId}\n`);

  console.log('=== Integration Complete ===');
}

// Export for use in other scripts
module.exports = { OnchainOSIntegration };

// Run demo if called directly
if (require.main === module) {
  demo().catch(console.error);
}
