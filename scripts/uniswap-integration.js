/**
 * COVENANT Protocol - Uniswap Skills Integration
 *
 * Off-chain wrapper for Uniswap V3 skills on X Layer.
 * Enables AI agents to:
 * - Get swap quotes and routes
 * - Execute token swaps via UniswapSkillRouter
 * - Query pool prices for task bounty valuation
 * - Manage liquidity positions
 *
 * Works alongside the on-chain UniswapSkillRouter contract.
 */

const { ethers } = require('ethers');

// Uniswap V3 contract addresses on X Layer
// These are the canonical Uniswap V3 deployment addresses
// Uniswap V3 addresses differ between mainnet and testnet.
// Mainnet addresses are canonical Uniswap V3 deployments.
// Testnet addresses should be configured via environment or updated after deployment.
const UNISWAP_ADDRESSES = {
  // X Layer Mainnet (Chain ID: 196)
  196: {
    swapRouter: process.env.UNISWAP_SWAP_ROUTER_MAINNET || '0xE592427A0AEce92De3Edee1F18E0157C05861564',
    quoterV2: process.env.UNISWAP_QUOTER_MAINNET || '0x61fFE014bA17989E743c5F6cB21bF9697530B21e',
    factory: process.env.UNISWAP_FACTORY_MAINNET || '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    nonfungiblePositionManager: '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
    WOKB: '0xe538905cf8410324e03A5A23C1c177a474D59b2b',
  },
  // X Layer Testnet (Chain ID: 1952) - configure via env vars after testnet deployment
  1952: {
    swapRouter: process.env.UNISWAP_SWAP_ROUTER_TESTNET || '',
    quoterV2: process.env.UNISWAP_QUOTER_TESTNET || '',
    factory: process.env.UNISWAP_FACTORY_TESTNET || '',
    nonfungiblePositionManager: process.env.UNISWAP_NFT_MANAGER_TESTNET || '',
    WOKB: process.env.WOKB_TESTNET || '',
  },
};

// UniswapSkillRouter ABI (deployed COVENANT contract)
const SKILL_ROUTER_ABI = [
  'function agentSwapExactInput(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, uint24 fee) external returns (uint256 amountOut)',
  'function agentSwapMultiHop(bytes calldata path, uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut)',
  'function getQuote(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut)',
  'function getAgentSwapStats(address agent) external view returns (uint256 swapCount, uint256 totalVolume)',
  'function approvedTokens(address token) external view returns (bool)',
];

// ERC20 ABI for approvals
const ERC20_ABI = [
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function allowance(address owner, address spender) external view returns (uint256)',
  'function balanceOf(address account) external view returns (uint256)',
  'function decimals() external view returns (uint8)',
  'function symbol() external view returns (string)',
];

class UniswapSkillIntegration {
  /**
   * @param {Object} config
   * @param {string} config.rpcUrl - X Layer RPC endpoint
   * @param {number} config.chainId - Chain ID (196 or 1952)
   * @param {string} config.skillRouterAddress - Deployed UniswapSkillRouter address
   * @param {string} [config.privateKey] - Agent wallet private key (for execution)
   */
  constructor({ rpcUrl, chainId, skillRouterAddress, privateKey }) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.chainId = chainId;
    this.addresses = UNISWAP_ADDRESSES[chainId];
    this.skillRouterAddress = skillRouterAddress;

    if (privateKey) {
      this.signer = new ethers.Wallet(privateKey, this.provider);
      this.router = new ethers.Contract(skillRouterAddress, SKILL_ROUTER_ABI, this.signer);
    } else {
      this.router = new ethers.Contract(skillRouterAddress, SKILL_ROUTER_ABI, this.provider);
    }
  }

  // ========== Quote & Price Functions ==========

  /**
   * Get a swap quote for token pair.
   * Agents use this to determine fair pricing for task bounties.
   *
   * @param {string} tokenIn - Input token address
   * @param {string} tokenOut - Output token address
   * @param {string} amountIn - Amount in base units
   * @returns {Object} Quote with expected output and price impact
   */
  async getSwapQuote(tokenIn, tokenOut, amountIn) {
    const tokenInContract = new ethers.Contract(tokenIn, ERC20_ABI, this.provider);
    const tokenOutContract = new ethers.Contract(tokenOut, ERC20_ABI, this.provider);

    const [symbolIn, symbolOut, decimalsIn, decimalsOut] = await Promise.all([
      tokenInContract.symbol(),
      tokenOutContract.symbol(),
      tokenInContract.decimals(),
      tokenOutContract.decimals(),
    ]);

    // Use the on-chain quoter via our skill router
    const amountOut = await this.router.getQuote.staticCall(tokenIn, tokenOut, amountIn);

    const ratePerToken = Number(amountOut) / Number(amountIn) * (10 ** Number(decimalsIn)) / (10 ** Number(decimalsOut));

    return {
      tokenIn: { address: tokenIn, symbol: symbolIn, decimals: Number(decimalsIn) },
      tokenOut: { address: tokenOut, symbol: symbolOut, decimals: Number(decimalsOut) },
      amountIn: ethers.formatUnits(amountIn, decimalsIn),
      amountOut: ethers.formatUnits(amountOut, decimalsOut),
      rate: ratePerToken.toFixed(6),
      route: `${symbolIn} -> ${symbolOut}`,
    };
  }

  // ========== Swap Execution ==========

  /**
   * Execute a token swap for an agent.
   *
   * @param {string} tokenIn - Input token address
   * @param {string} tokenOut - Output token address
   * @param {string} amountIn - Amount in base units
   * @param {number} slippageBps - Slippage in basis points (e.g., 50 = 0.5%)
   * @param {number} fee - Pool fee tier (500, 3000, 10000)
   * @returns {Object} Swap result with tx hash and amounts
   */
  async executeSwap(tokenIn, tokenOut, amountIn, slippageBps = 50, fee = 3000) {
    if (!this.signer) throw new Error('Signer required for swap execution');

    // Get quote first for minimum output calculation
    const expectedOut = await this.router.getQuote.staticCall(tokenIn, tokenOut, amountIn);
    const amountOutMin = expectedOut * BigInt(10000 - slippageBps) / BigInt(10000);

    // Approve token spending
    const token = new ethers.Contract(tokenIn, ERC20_ABI, this.signer);
    const currentAllowance = await token.allowance(this.signer.address, this.skillRouterAddress);

    if (currentAllowance < BigInt(amountIn)) {
      console.log('Approving token spend...');
      const approveTx = await token.approve(this.skillRouterAddress, ethers.MaxUint256);
      await approveTx.wait();
    }

    // Execute swap through COVENANT's UniswapSkillRouter
    console.log(`Swapping ${ethers.formatUnits(amountIn, 18)} tokens...`);
    const tx = await this.router.agentSwapExactInput(
      tokenIn,
      tokenOut,
      amountIn,
      amountOutMin,
      fee
    );

    const receipt = await tx.wait();

    // Parse swap event
    const swapEvent = receipt.logs.find(
      (log) => log.topics[0] === ethers.id('AgentSwap(address,address,address,uint256,uint256,uint256)')
    );

    return {
      txHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      amountIn: amountIn.toString(),
      amountOutMin: amountOutMin.toString(),
      fee,
      gasUsed: receipt.gasUsed.toString(),
    };
  }

  // ========== Agent Stats ==========

  /**
   * Get swap statistics for an agent.
   * Used by the reputation system to factor in trading activity.
   *
   * @param {string} agentAddress - Agent wallet address
   * @returns {Object} Swap count and total volume
   */
  async getAgentStats(agentAddress) {
    const [swapCount, totalVolume] = await this.router.getAgentSwapStats(agentAddress);

    return {
      agentAddress,
      swapCount: Number(swapCount),
      totalVolume: ethers.formatEther(totalVolume),
    };
  }

  /**
   * Check if a token is approved for swaps.
   *
   * @param {string} tokenAddress - Token to check
   * @returns {boolean} Whether the token is approved
   */
  async isTokenApproved(tokenAddress) {
    return this.router.approvedTokens(tokenAddress);
  }
}

// ========== Demo ==========

async function demo() {
  console.log('=== COVENANT x Uniswap Skills Integration Demo ===\n');

  const XLAYER_TESTNET_RPC = 'https://testrpc.xlayer.tech';
  const CHAIN_ID = 1952;

  // Set via UNISWAP_SKILL_ROUTER env var after deploying UniswapSkillRouter.sol
  const SKILL_ROUTER = process.env.UNISWAP_SKILL_ROUTER || '';

  const uniswap = new UniswapSkillIntegration({
    rpcUrl: XLAYER_TESTNET_RPC,
    chainId: CHAIN_ID,
    skillRouterAddress: SKILL_ROUTER,
  });

  console.log('Uniswap V3 addresses on X Layer:');
  console.log(`  SwapRouter: ${UNISWAP_ADDRESSES[CHAIN_ID].swapRouter}`);
  console.log(`  QuoterV2:   ${UNISWAP_ADDRESSES[CHAIN_ID].quoterV2}`);
  console.log(`  Factory:    ${UNISWAP_ADDRESSES[CHAIN_ID].factory}`);
  console.log(`  WOKB:       ${UNISWAP_ADDRESSES[CHAIN_ID].WOKB}`);
  console.log();

  console.log('Available agent operations:');
  console.log('  1. getSwapQuote(tokenIn, tokenOut, amount) - Price discovery for task bounties');
  console.log('  2. executeSwap(tokenIn, tokenOut, amount)  - Convert earned tokens');
  console.log('  3. getAgentStats(address)                  - Swap history for reputation');
  console.log();

  console.log('=== Integration Ready ===');
}

module.exports = { UniswapSkillIntegration, UNISWAP_ADDRESSES };

if (require.main === module) {
  demo().catch(console.error);
}
