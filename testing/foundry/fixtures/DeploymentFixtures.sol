// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

// Original contracts
import {AgentRegistry} from "../../../contracts/AgentRegistry.sol";
import {AgentCovenant} from "../../../contracts/AgentCovenant.sol";
import {CovenantFactory as OldCovenantFactory} from "../../../contracts/CovenantFactory.sol";
import {ReputationStake as OldReputationStake} from "../../../contracts/ReputationStake.sol";
import {TaskMarket as OldTaskMarket} from "../../../contracts/TaskMarket.sol";
import {DisputeDAO as OldDisputeDAO} from "../../../contracts/core/DisputeDAO.sol";

// V2 contracts - core
import {CovenantFactory} from "../../../contracts-v2/core/CovenantFactory.sol";
import {CovenantRegistry} from "../../../contracts-v2/core/CovenantRegistry.sol";
import {CovenantImplementation} from "../../../contracts-v2/core/CovenantImplementation.sol";
import {CovenantProxy} from "../../../contracts-v2/core/CovenantProxy.sol";

// V2 contracts - task
import {TaskMarket} from "../../../contracts-v2/task/TaskMarket.sol";

// V2 contracts - reputation
import {ReputationStake} from "../../../contracts-v2/reputation/ReputationStake.sol";

// V2 contracts - governance
import {CovenantGovernor} from "../../../contracts-v2/governance/CovenantGovernor.sol";

// V2 contracts - tokenomics
import {COVEN} from "../../../contracts-v2/tokenomics/COVEN.sol";

/**
 * @title DeploymentFixtures
 * @notice Base fixture for deploying all protocol contracts
 */
contract DeploymentFixtures is Test {
    // Users
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public dave = makeAddr("dave");
    address public feeRecipient = makeAddr("feeRecipient");
    address public treasury = makeAddr("treasury");

    // Tokens
    MockERC20 public token;
    MockERC20 public rewardToken;
    COVEN public covenToken;

    // Original contracts
    AgentRegistry public agentRegistry;
    OldCovenantFactory public oldFactory;
    OldReputationStake public oldReputationStake;
    OldTaskMarket public oldTaskMarket;
    OldDisputeDAO public oldDisputeDAO;

    // V2 contracts
    CovenantImplementation public implementation;
    CovenantRegistry public registry;
    CovenantFactory public factory;
    TaskMarket public taskMarket;
    ReputationStake public reputationStake;
    CovenantGovernor public governor;

    function setUp() public virtual {
        vm.startPrank(owner);

        // Deploy tokens
        token = new MockERC20("Mock Token", "MCK", 18);
        rewardToken = new MockERC20("Reward Token", "RWD", 18);
        covenToken = new COVEN("COVEN Token", "COVEN", 1_000_000_000 ether, 500);

        // Deploy original contracts
        agentRegistry = new AgentRegistry();
        oldFactory = new OldCovenantFactory(feeRecipient);
        oldReputationStake = new OldReputationStake(address(token), feeRecipient);
        oldTaskMarket = new OldTaskMarket(feeRecipient);

        // Deploy V2 contracts
        implementation = new CovenantImplementation();
        registry = new CovenantRegistry(address(0x1));
        registry = new CovenantRegistry(address(this));
        factory = new CovenantFactory(address(implementation), address(registry));
        registry.setFactory(address(factory));
        taskMarket = new TaskMarket();
        reputationStake = new ReputationStake(address(token));
        governor = new CovenantGovernor(address(covenToken), 1000 ether, 1 days, 7 days);

        vm.stopPrank();

        // Fund users
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(carol, 1000 ether);
        vm.deal(dave, 1000 ether);
        vm.deal(owner, 1000 ether);
        vm.deal(feeRecipient, 1000 ether);
        vm.deal(treasury, 1000 ether);

        // Mint tokens
        token.mint(alice, 1_000_000 ether);
        token.mint(bob, 1_000_000 ether);
        token.mint(carol, 1_000_000 ether);
        token.mint(dave, 1_000_000 ether);
        token.mint(owner, 1_000_000 ether);

        rewardToken.mint(alice, 1_000_000 ether);
        rewardToken.mint(bob, 1_000_000 ether);
    }

    modifier asOwner() {
        vm.prank(owner);
        _;
    }

    modifier asAlice() {
        vm.prank(alice);
        _;
    }

    modifier asBob() {
        vm.prank(bob);
        _;
    }

    modifier asCarol() {
        vm.prank(carol);
        _;
    }
}
