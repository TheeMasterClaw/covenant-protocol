// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title UniswapSkillRouter
 * @notice COVENANT Protocol integration with Uniswap V3 skills on X Layer.
 *         Enables AI agents to swap earned tokens, query prices, and manage
 *         liquidity through the COVENANT task marketplace.
 * @dev Wraps the Uniswap V3 SwapRouter for agent-initiated swaps.
 *      Designed for the OKX Build X Hackathon - X Layer Arena.
 */
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IQuoterV2 {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

contract UniswapSkillRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State ============

    address public owner;
    address public swapRouter;
    address public quoter;
    address public agentRegistry;

    // Default fee tier for X Layer pools
    uint24 public constant DEFAULT_FEE = 3000; // 0.3%

    // Protocol fee on agent swaps (basis points)
    uint256 public protocolFeeBps = 10; // 0.1%
    address public feeCollector;

    // Approved tokens for agent swaps
    mapping(address => bool) public approvedTokens;

    // Agent swap history
    mapping(address => uint256) public agentSwapCount;
    mapping(address => uint256) public agentSwapVolume;

    // ============ Events ============

    event AgentSwap(
        address indexed agent,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );

    event TokenApproved(address indexed token, bool approved);
    event ProtocolFeeUpdated(uint256 newFeeBps);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ============ Constructor ============

    /**
     * @param _swapRouter Uniswap V3 SwapRouter address on X Layer
     * @param _quoter Uniswap V3 QuoterV2 address on X Layer
     * @param _agentRegistry COVENANT AgentRegistry address
     */
    constructor(address _swapRouter, address _quoter, address _agentRegistry) {
        owner = msg.sender;
        swapRouter = _swapRouter;
        quoter = _quoter;
        agentRegistry = _agentRegistry;
        feeCollector = msg.sender;
    }

    // ============ Agent Swap Functions ============

    /**
     * @notice Execute a single-hop swap for an agent.
     *         Agents call this to convert earned tokens (e.g., COV -> OKB).
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens
     * @param amountOutMin Minimum output (slippage protection)
     * @param fee Pool fee tier (500, 3000, or 10000)
     * @return amountOut Actual output amount
     */
    function agentSwapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee
    ) external nonReentrant returns (uint256 amountOut) {
        require(approvedTokens[tokenIn] && approvedTokens[tokenOut], "Token not approved");

        // Transfer tokens from agent
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calculate and collect protocol fee
        uint256 feeAmount = (amountIn * protocolFeeBps) / 10000;
        uint256 swapAmount = amountIn - feeAmount;

        if (feeAmount > 0) {
            IERC20(tokenIn).safeTransfer(feeCollector, feeAmount);
        }

        // Approve router
        IERC20(tokenIn).approve(swapRouter, swapAmount);

        // Execute swap via Uniswap V3
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp + 300, // 5 minute deadline
            amountIn: swapAmount,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(swapRouter).exactInputSingle(params);

        // Track agent swap stats
        agentSwapCount[msg.sender]++;
        agentSwapVolume[msg.sender] += amountIn;

        emit AgentSwap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, block.timestamp);
    }

    /**
     * @notice Execute a multi-hop swap for an agent.
     *         Used for paths like COV -> WOKB -> USDT.
     * @param path Encoded swap path (tokenA, fee, tokenB, fee, tokenC)
     * @param amountIn Amount of input tokens
     * @param amountOutMin Minimum output (slippage protection)
     * @return amountOut Actual output amount
     */
    function agentSwapMultiHop(
        bytes calldata path,
        uint256 amountIn,
        uint256 amountOutMin
    ) external nonReentrant returns (uint256 amountOut) {
        // Decode first token from path
        address tokenIn;
        assembly {
            tokenIn := shr(96, calldataload(path.offset))
        }

        // Transfer tokens from agent
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Protocol fee
        uint256 feeAmount = (amountIn * protocolFeeBps) / 10000;
        uint256 swapAmount = amountIn - feeAmount;

        if (feeAmount > 0) {
            IERC20(tokenIn).safeTransfer(feeCollector, feeAmount);
        }

        // Approve router
        IERC20(tokenIn).approve(swapRouter, swapAmount);

        // Execute multi-hop swap
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: msg.sender,
            deadline: block.timestamp + 300,
            amountIn: swapAmount,
            amountOutMinimum: amountOutMin
        });

        amountOut = ISwapRouter(swapRouter).exactInput(params);

        agentSwapCount[msg.sender]++;
        agentSwapVolume[msg.sender] += amountIn;

        emit AgentSwap(msg.sender, tokenIn, address(0), amountIn, amountOut, block.timestamp);
    }

    // ============ Price Query Functions ============

    /**
     * @notice Get a swap quote for an agent.
     *         Used to price task bounties in different tokens.
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param amountIn Amount to quote
     * @return amountOut Expected output amount
     */
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        (amountOut,,,) = IQuoterV2(quoter).quoteExactInputSingle(
            tokenIn,
            tokenOut,
            DEFAULT_FEE,
            amountIn,
            0
        );
    }

    // ============ Admin Functions ============

    function approveToken(address token, bool approved) external onlyOwner {
        approvedTokens[token] = approved;
        emit TokenApproved(token, approved);
    }

    function setProtocolFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 100, "Fee too high"); // Max 1%
        protocolFeeBps = newFeeBps;
        emit ProtocolFeeUpdated(newFeeBps);
    }

    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Zero address");
        feeCollector = newCollector;
    }

    // ============ View Functions ============

    function getAgentSwapStats(address agent) external view returns (uint256 swapCount, uint256 totalVolume) {
        return (agentSwapCount[agent], agentSwapVolume[agent]);
    }
}
