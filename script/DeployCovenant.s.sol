// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts-v2/core/CovenantFactory.sol";
import "../contracts-v2/core/CovenantImplementation.sol";
import "../contracts-v2/core/CovenantRegistry.sol";
import "../contracts-v2/task/TaskMarket.sol";
import "../contracts-v2/task/TaskAuction.sol";
import "../contracts-v2/task/TaskEscrow.sol";
import "../contracts-v2/reputation/ReputationStake.sol";
import "../contracts-v2/reputation/ReputationOracle.sol";
import "../contracts-v2/dispute/DisputeDAO.sol";
import "../contracts-v2/dispute/DisputeJury.sol";
import "../contracts-v2/dispute/DisputeEvidence.sol";
import "../contracts-v2/governance/CovenantToken.sol";
import "../contracts-v2/governance/CovenantGovernor.sol";
import "../contracts-v2/governance/CovenantTimelock.sol";
import "../contracts-v2/ai/AgentRegistry.sol";
import "../contracts-v2/ai/ReputationAggregator.sol";
import "../contracts-v2/tokenomics/StakingPool.sol";
import "../contracts-v2/crosschain/CovenantBridgeRouter.sol";

contract DeployCovenant is Script {
    struct Deployment {
        address factory;
        address implementation;
        address registry;
        address taskMarket;
        address taskAuction;
        address taskEscrow;
        address reputationStake;
        address reputationOracle;
        address disputeDAO;
        address disputeJury;
        address disputeEvidence;
        address covenToken;
        address timelock;
        address governor;
        address agentRegistry;
        address reputationAggregator;
        address stakingPool;
        address bridgeRouter;
    }

    Deployment public deployment;

    function run() external returns (Deployment memory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying COVENANT Protocol...");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // ============================================
        // PHASE 1: Core Protocol
        // ============================================
        console.log("\n=== PHASE 1: Core Protocol ===");

        CovenantImplementation implementation = new CovenantImplementation();
        deployment.implementation = address(implementation);
        console.log("CovenantImplementation:", deployment.implementation);

        CovenantFactory factory = new CovenantFactory(
            deployment.implementation,
            address(0) // registry placeholder, will set later
        );
        deployment.factory = address(factory);
        console.log("CovenantFactory:", deployment.factory);

        CovenantRegistry registry = new CovenantRegistry(deployment.factory);
        deployment.registry = address(registry);
        console.log("CovenantRegistry:", deployment.registry);

        // Update factory with real registry
        factory.setRegistry(deployment.registry);
        console.log("Registry set in Factory");

        // ============================================
        // PHASE 2: Task Layer
        // ============================================
        console.log("\n=== PHASE 2: Task Layer ===");

        TaskMarket taskMarket = new TaskMarket();
        deployment.taskMarket = address(taskMarket);
        console.log("TaskMarket:", deployment.taskMarket);

        TaskAuction taskAuction = new TaskAuction();
        deployment.taskAuction = address(taskAuction);
        console.log("TaskAuction:", deployment.taskAuction);

        TaskEscrow taskEscrow = new TaskEscrow();
        deployment.taskEscrow = address(taskEscrow);
        console.log("TaskEscrow:", deployment.taskEscrow);

        // ============================================
        // PHASE 3: Reputation Layer
        // ============================================
        console.log("\n=== PHASE 3: Reputation Layer ===");

        // Deploy token first for reputation staking
        CovenantToken covenToken = new CovenantToken(
            "COVENANT",
            "COVEN",
            1_000_000_000 * 1e18 // 1B max supply
        );
        deployment.covenToken = address(covenToken);
        console.log("CovenantToken:", deployment.covenToken);

        ReputationStake reputationStake = new ReputationStake(deployment.covenToken);
        deployment.reputationStake = address(reputationStake);
        console.log("ReputationStake:", deployment.reputationStake);

        ReputationOracle reputationOracle = new ReputationOracle();
        deployment.reputationOracle = address(reputationOracle);
        console.log("ReputationOracle:", deployment.reputationOracle);

        // ============================================
        // PHASE 4: Dispute Layer
        // ============================================
        console.log("\n=== PHASE 4: Dispute Layer ===");

        DisputeEvidence disputeEvidence = new DisputeEvidence();
        deployment.disputeEvidence = address(disputeEvidence);
        console.log("DisputeEvidence:", deployment.disputeEvidence);

        DisputeJury disputeJury = new DisputeJury(deployment.covenToken);
        deployment.disputeJury = address(disputeJury);
        console.log("DisputeJury:", deployment.disputeJury);

        DisputeDAO disputeDAO = new DisputeDAO();
        deployment.disputeDAO = address(disputeDAO);
        console.log("DisputeDAO:", deployment.disputeDAO);

        // ============================================
        // PHASE 5: Governance
        // ============================================
        console.log("\n=== PHASE 5: Governance ===");

        CovenantTimelock timelock = new CovenantTimelock(2 days);
        deployment.timelock = address(timelock);
        console.log("CovenantTimelock:", deployment.timelock);

        CovenantGovernor governor = new CovenantGovernor(
            deployment.covenToken,
            4, // quorum
            1, // voting delay
            50400 // voting period
        );
        deployment.governor = address(governor);
        console.log("CovenantGovernor:", deployment.governor);

        // ============================================
        // PHASE 6: AI Layer
        // ============================================
        console.log("\n=== PHASE 6: AI Layer ===");

        AgentRegistry agentRegistry = new AgentRegistry();
        deployment.agentRegistry = address(agentRegistry);
        console.log("AgentRegistry:", deployment.agentRegistry);

        // ReputationAggregator has no constructor
        ReputationAggregator reputationAggregator = new ReputationAggregator();
        deployment.reputationAggregator = address(reputationAggregator);
        console.log("ReputationAggregator:", deployment.reputationAggregator);

        // ============================================
        // PHASE 7: Tokenomics
        // ============================================
        console.log("\n=== PHASE 7: Tokenomics ===");

        StakingPool stakingPool = new StakingPool(
            deployment.covenToken,
            deployment.covenToken
        );
        deployment.stakingPool = address(stakingPool);
        console.log("StakingPool:", deployment.stakingPool);

        // ============================================
        // PHASE 8: Cross-Chain
        // ============================================
        console.log("\n=== PHASE 8: Cross-Chain ===");

        CovenantBridgeRouter bridgeRouter = new CovenantBridgeRouter(
            address(0), // covenantBridge placeholder
            deployer
        );
        deployment.bridgeRouter = address(bridgeRouter);
        console.log("CovenantBridgeRouter:", deployment.bridgeRouter);

        // ============================================
        // INITIALIZATION & FUNDING
        // ============================================
        console.log("\n=== INITIALIZATION ===");

        // Transfer timelock ownership to governor
        timelock.transferOwnership(deployment.governor);
        console.log("Timelock ownership transferred to Governor");

        // Fund initial ecosystem
        covenToken.transfer(deployment.stakingPool, 10_000_000 * 1e18); // 10M for rewards
        covenToken.transfer(deployment.disputeDAO, 5_000_000 * 1e18); // 5M for dispute rewards
        console.log("Initial ecosystem funding complete");

        vm.stopBroadcast();

        // ============================================
        // SUMMARY
        // ============================================
        console.log("\n========================================");
        console.log("DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("Network:", block.chainid == 195 ? "X Layer Testnet" : "Unknown");
        console.log("Total contracts deployed: 18");

        return deployment;
    }
}
