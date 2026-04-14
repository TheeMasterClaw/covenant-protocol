// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {AgentRegistry} from "../../contracts/AgentRegistry.sol";
import {AgentCovenant} from "../../contracts/AgentCovenant.sol";
import {CovenantFactory as OldCovenantFactory} from "../../contracts/CovenantFactory.sol";
import {ReputationStake as OldReputationStake} from "../../contracts/ReputationStake.sol";
import {TaskMarket as OldTaskMarket} from "../../contracts/TaskMarket.sol";
import {DisputeDAO as OldDisputeDAO} from "../../contracts/core/DisputeDAO.sol";
import {CovenantFactory} from "../../contracts-v2/core/CovenantFactory.sol";
import {CovenantRegistry} from "../../contracts-v2/core/CovenantRegistry.sol";
import {CovenantImplementation} from "../../contracts-v2/core/CovenantImplementation.sol";
import {TaskMarket} from "../../contracts-v2/task/TaskMarket.sol";
import {ReputationStake} from "../../contracts-v2/reputation/ReputationStake.sol";
import {COVEN} from "../../contracts-v2/tokenomics/COVEN.sol";
import {CovenantGovernor} from "../../contracts-v2/governance/CovenantGovernor.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mocks
        MockERC20 token = new MockERC20("Test Token", "TEST", 18);
        MockERC20 rewardToken = new MockERC20("Reward Token", "RWD", 18);

        // Deploy v1 contracts
        AgentRegistry agentRegistry = new AgentRegistry();
        AgentCovenant agentCovenant = new AgentCovenant(
            deployer,
            address(0x1234),
            keccak256("TEST"),
            "ipfs://test",
            7 days,
            0.01 ether,
            deployer,
            100
        );
        OldCovenantFactory oldFactory = new OldCovenantFactory(deployer);
        OldReputationStake oldStake = new OldReputationStake(address(token), deployer);
        OldTaskMarket oldTaskMarket = new OldTaskMarket(deployer);
        OldDisputeDAO oldDisputeDAO = new OldDisputeDAO(address(token), address(oldStake));

        // Deploy v2 contracts
        // Break circular dependency: CovenantFactory needs registry, CovenantRegistry needs factory
        // Predict factory address (will be deployed after implementation and registry)
        uint256 factoryNonce = vm.getNonce(deployer) + 3;
        address predictedFactory = vm.computeCreateAddress(deployer, factoryNonce);

        CovenantImplementation implementation = new CovenantImplementation();
        CovenantRegistry registry = new CovenantRegistry(predictedFactory);
        CovenantFactory factory = new CovenantFactory(address(implementation), address(registry));
        
        // Sanity check prediction
        require(address(factory) == predictedFactory, "Factory address prediction mismatch");

        TaskMarket taskMarket = new TaskMarket();
        ReputationStake reputationStake = new ReputationStake(address(token));
        COVEN covenToken = new COVEN("COVEN Token", "COVEN", 1_000_000_000 ether, 500);
        CovenantGovernor governor = new CovenantGovernor(address(covenToken), 1000 ether, 1 days, 7 days);

        // Wire v2 contracts
        registry.setFactory(address(factory));
        covenToken.setStakingContract(address(reputationStake));

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("=== V1 Contracts ===");
        console.log("AgentRegistry:", address(agentRegistry));
        console.log("AgentCovenant:", address(agentCovenant));
        console.log("OldCovenantFactory:", address(oldFactory));
        console.log("OldReputationStake:", address(oldStake));
        console.log("OldTaskMarket:", address(oldTaskMarket));
        console.log("OldDisputeDAO:", address(oldDisputeDAO));
        console.log("=== V2 Contracts ===");
        console.log("CovenantFactory:", address(factory));
        console.log("CovenantRegistry:", address(registry));
        console.log("CovenantImplementation:", address(implementation));
        console.log("TaskMarket:", address(taskMarket));
        console.log("ReputationStake:", address(reputationStake));
        console.log("COVEN:", address(covenToken));
        console.log("CovenantGovernor:", address(governor));
        console.log("=== Mocks ===");
        console.log("TestToken:", address(token));
        console.log("RewardToken:", address(rewardToken));
    }
}
