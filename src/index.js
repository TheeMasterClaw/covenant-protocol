/**
 * COVENANT Protocol SDK
 * JavaScript interface for AI agents to interact with the protocol
 */

const { ethers } = require('ethers');
const CovenantFactoryABI = require('../artifacts/contracts/CovenantFactory.sol/CovenantFactory.json');
const AgentCovenantABI = require('../artifacts/contracts/AgentCovenant.sol/AgentCovenant.json');
const TaskMarketABI = require('../artifacts/contracts/TaskMarket.sol/TaskMarket.json');
const ReputationStakeABI = require('../artifacts/contracts/ReputationStake.sol/ReputationStake.json');

class CovenantSDK {
  constructor(config) {
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    this.wallet = new ethers.Wallet(config.privateKey, this.provider);
    this.agentId = config.agentId;
    
    // Contract addresses (set after deployment)
    this.addresses = config.contracts || {};
    
    // Initialize contracts
    if (this.addresses.factory) {
      this.factory = new ethers.Contract(
        this.addresses.factory,
        CovenantFactoryABI.abi,
        this.wallet
      );
    }
    
    if (this.addresses.taskMarket) {
      this.taskMarket = new ethers.Contract(
        this.addresses.taskMarket,
        TaskMarketABI.abi,
        this.wallet
      );
    }
    
    if (this.addresses.reputationStake) {
      this.reputationStake = new ethers.Contract(
        this.addresses.reputationStake,
        ReputationStakeABI.abi,
        this.wallet
      );
    }
  }

  // ============ Covenant Functions ============

  /**
   * Create a new covenant with another agent
   */
  async createCovenant(counterparty, covenantType, termsIPFS, duration, stakeAmount) {
    const tx = await this.factory.createCovenant(
      counterparty,
      ethers.encodeBytes32String(covenantType),
      termsIPFS,
      duration,
      { value: ethers.parseEther(stakeAmount.toString()) }
    );
    
    const receipt = await tx.wait();
    
    // Parse event to get covenant address
    const event = receipt.logs.find(
      log => log.fragment?.name === 'CovenantCreated'
    );
    
    return {
      txHash: receipt.hash,
      covenantAddress: event?.args?.covenantAddress,
      stakeAmount: stakeAmount
    };
  }

  /**
   * Get covenant instance
   */
  async getCovenant(covenantAddress) {
    return new ethers.Contract(
      covenantAddress,
      AgentCovenantABI.abi,
      this.wallet
    );
  }

  /**
   * Accept a covenant
   */
  async acceptCovenant(covenantAddress) {
    const covenant = await this.getCovenant(covenantAddress);
    const tx = await covenant.acceptCovenant();
    return await tx.wait();
  }

  /**
   * Add milestone to covenant
   */
  async addMilestone(covenantAddress, description, paymentAmount) {
    const covenant = await this.getCovenant(covenantAddress);
    const tx = await covenant.addMilestone(
      description,
      ethers.parseEther(paymentAmount.toString())
    );
    return await tx.wait();
  }

  /**
   * Complete milestone
   */
  async completeMilestone(covenantAddress, milestoneIndex) {
    const covenant = await this.getCovenant(covenantAddress);
    const tx = await covenant.completeMilestone(milestoneIndex);
    return await tx.wait();
  }

  /**
   * Pay milestone
   */
  async payMilestone(covenantAddress, milestoneIndex) {
    const covenant = await this.getCovenant(covenantAddress);
    const tx = await covenant.payMilestone(milestoneIndex);
    return await tx.wait();
  }

  // ============ Task Market Functions ============

  /**
   * Post a task
   */
  async postTask(title, description, requirementsIPFS, reward, priority = 1) {
    const tx = await this.taskMarket.postTask(
      title,
      description,
      requirementsIPFS,
      ethers.parseEther(reward.toString()),
      priority,
      { value: ethers.parseEther(reward.toString()) }
    );
    
    const receipt = await tx.wait();
    
    // Parse event to get task ID
    const event = receipt.logs.find(
      log => log.fragment?.name === 'TaskPosted'
    );
    
    return {
      txHash: receipt.hash,
      taskId: event?.args?.taskId?.toString()
    };
  }

  /**
   * Bid on a task
   */
  async bidOnTask(taskId, amount, estimatedTime, proposalIPFS) {
    const tx = await this.taskMarket.bidOnTask(
      taskId,
      ethers.parseEther(amount.toString()),
      estimatedTime,
      proposalIPFS
    );
    return await tx.wait();
  }

  /**
   * Accept a bid
   */
  async acceptBid(taskId, bidIndex) {
    const tx = await this.taskMarket.acceptBid(taskId, bidIndex);
    return await tx.wait();
  }

  /**
   * Start work on task
   */
  async startWork(taskId) {
    const tx = await this.taskMarket.startWork(taskId);
    return await tx.wait();
  }

  /**
   * Submit work
   */
  async submitWork(taskId, resultIPFS) {
    const tx = await this.taskMarket.submitWork(taskId, resultIPFS);
    return await tx.wait();
  }

  /**
   * Approve work and release payment
   */
  async approveWork(taskId) {
    const tx = await this.taskMarket.approveWork(taskId);
    return await tx.wait();
  }

  /**
   * Get task details
   */
  async getTask(taskId) {
    return await this.taskMarket.getTask(taskId);
  }

  /**
   * Get open tasks
   */
  async getOpenTasks(offset = 0, limit = 10) {
    return await this.taskMarket.getOpenTasks(offset, limit);
  }

  /**
   * Get agent stats
   */
  async getAgentStats(agentAddress) {
    return await this.taskMarket.getAgentStats(agentAddress);
  }

  // ============ Reputation Functions ============

  /**
   * Register as an agent
   */
  async registerAgent(metadataURI) {
    const tx = await this.reputationStake.registerAgent(metadataURI);
    return await tx.wait();
  }

  /**
   * Stake tokens
   */
  async stake(amount) {
    const tx = await this.reputationStake.stake(
      ethers.parseEther(amount.toString())
    );
    return await tx.wait();
  }

  /**
   * Calculate reputation
   */
  async calculateReputation(agentAddress) {
    return await this.reputationStake.calculateReputation(agentAddress);
  }

  /**
   * Get agent profile
   */
  async getAgentProfile(agentAddress) {
    return await this.reputationStake.getAgentProfile(agentAddress);
  }

  // ============ Utility Functions ============

  /**
   * Get wallet balance
   */
  async getBalance() {
    return await this.provider.getBalance(this.wallet.address);
  }

  /**
   * Get covenant count
   */
  async getCovenantCount() {
    return await this.factory.getCovenantCount();
  }

  /**
   * Get all covenants
   */
  async getCovenants(offset, limit) {
    return await this.factory.getCovenants(offset, limit);
  }
}

module.exports = CovenantSDK;
