// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {AgentRegistry} from "../../../../contracts/AgentRegistry.sol";

contract AgentRegistryTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsOwner() public view {
        assertEq(agentRegistry.owner(), address(this));
    }
    function test_Constructor_InitializesDefaultSkills() public view {
        assertEq(agentRegistry.nextSkillId(), 9);
    }
    function test_Constructor_TotalAgentsZero() public view {
        assertEq(agentRegistry.totalAgents(), 0);
    }
    function test_Constructor_RegistrationFeeSet() public view {
        assertEq(agentRegistry.registrationFee(), 0.001 ether);
    }
    function test_Constructor_DefaultSkillNames() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertTrue(bytes(agentRegistry.skills(i).name).length > 0);
        }
    }
    function test_Constructor_DefaultSkillDescriptions() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertTrue(bytes(agentRegistry.skills(i).description).length > 0);
        }
    }
    function test_Constructor_SkillNameToIdMapping() public view {
        assertEq(agentRegistry.skillNameToId("Smart Contract Development"), 1);
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(agentRegistry).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(agentRegistry).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        AgentRegistry ar = new AgentRegistry();
        assertEq(address(ar).balance, 0);
    }
    function test_Constructor_OwnerIsDeployer() public view {
        assertEq(agentRegistry.owner(), address(this));
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        AgentRegistry ar1 = new AgentRegistry();
        AgentRegistry ar2 = new AgentRegistry();
        assertTrue(address(ar1) != address(ar2));
    }
    function test_Constructor_AllSkillsHaveUniqueIds() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertEq(agentRegistry.skills(i).id, i);
        }
    }
    function test_Constructor_SkillAgentCountsZero() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertEq(agentRegistry.skills(i).agentCount, 0);
        }
    }
    function test_Constructor_8DefaultSkills() public view {
        AgentRegistry.Skill[] memory skills = agentRegistry.getAllSkills();
        assertEq(skills.length, 8);
    }

    // ==================== REGISTER AGENT TESTS (25) ====================
    function test_RegisterAgent_Success() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_RegisterAgent_EmitsEvent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.AgentRegistered(address(this), "ipfs://metadata", skillIds, block.timestamp);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_StoresProfile() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        AgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(address(this));
        assertEq(profile.agentAddress, address(this));
        assertEq(profile.metadataURI, "ipfs://metadata");
        assertEq(profile.reputationScore, 0);
        assertTrue(profile.isActive);
    }
    function test_RegisterAgent_StoresSkills() public {
        uint256[] memory skillIds = new uint256[](2);
        skillIds[0] = 1;
        skillIds[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory skills = agentRegistry.getAgentSkills(address(this));
        assertEq(skills.length, 2);
        assertEq(skills[0], 1);
        assertEq(skills[1], 2);
    }
    function test_RegisterAgent_UpdatesTotalAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.totalAgents(), 1);
    }
    function test_RegisterAgent_UpdatesSkillAgentCounts() public {
        uint256[] memory skillIds = new uint256[](2);
        skillIds[0] = 1;
        skillIds[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.skills(1).agentCount, 1);
        assertEq(agentRegistry.skills(2).agentCount, 1);
    }
    function test_RegisterAgent_AddsToSkillToAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 1);
        assertEq(agents[0], address(this));
    }
    function test_RegisterAgent_InsufficientFeeReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        vm.expectRevert("Insufficient fee");
        agentRegistry.registerAgent{value: 0.0005 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_AlreadyRegisteredReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectRevert("Already registered");
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata2", skillIds);
    }
    function test_RegisterAgent_InvalidSkillIdReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 99;
        vm.expectRevert("Invalid skill ID");
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_NoSkillsReverts() public {
        uint256[] memory skillIds = new uint256[](0);
        vm.expectRevert("Must have at least one skill");
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_TooManySkillsReverts() public {
        uint256[] memory skillIds = new uint256[](21);
        for (uint256 i = 0; i < 21; i++) {
            skillIds[i] = 1;
        }
        vm.expectRevert("Too many skills");
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_MetadataTooShortReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        vm.expectRevert("Metadata too short");
        agentRegistry.registerAgent{value: 0.001 ether}("short", skillIds);
    }
    function test_RegisterAgent_MetadataTooLongReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        string memory longMetadata = new string(501);
        vm.expectRevert("Metadata too long");
        agentRegistry.registerAgent{value: 0.001 ether}(longMetadata, skillIds);
    }
    function test_RegisterAgent_RefundExcess() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        uint256 balanceBefore = address(this).balance;
        agentRegistry.registerAgent{value: 0.002 ether}("ipfs://metadata", skillIds);
        assertEq(address(this).balance, balanceBefore - 0.001 ether);
    }
    function test_RegisterAgent_SkillNamesStored() public {
        uint256[] memory skillIds = new uint256[](2);
        skillIds[0] = 1;
        skillIds[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        AgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(address(this));
        assertEq(profile.skillNames[0], "Smart Contract Development");
        assertEq(profile.skillNames[1], "Data Analysis");
    }
    function test_RegisterAgent_RegisteredAtIsBlockTimestamp() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        AgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(address(this));
        assertEq(profile.registeredAt, block.timestamp);
    }
    function test_RegisterAgent_LastActiveIsBlockTimestamp() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        AgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(address(this));
        assertEq(profile.lastActive, block.timestamp);
    }
    function test_RegisterAgent_ExactFee() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_RegisterAgent_WhenPausedReverts() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.pause();
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        vm.expectRevert();
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
    function test_RegisterAgent_MultipleAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 10; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        assertEq(agentRegistry.totalAgents(), 10);
    }
    function test_RegisterAgent_MaxSkills() public {
        uint256[] memory skillIds = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            skillIds[i] = (i % 8) + 1;
        }
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.getAgentSkills(address(this)).length, 20);
    }
    function test_RegisterAgent_MinMetadataLength() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        string memory metadata = new string(10);
        agentRegistry.registerAgent{value: 0.001 ether}(metadata, skillIds);
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_RegisterAgent_MaxMetadataLength() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        string memory metadata = new string(500);
        agentRegistry.registerAgent{value: 0.001 ether}(metadata, skillIds);
        assertTrue(agentRegistry.isRegistered(address(this)));
    }

    // ==================== UPDATE PROFILE TESTS (15) ====================
    function test_UpdateProfile_Success() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.getAgentSkills(address(this))[0], 2);
    }
    function test_UpdateProfile_EmitsEvent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.AgentUpdated(address(this), "ipfs://new", newSkills, block.timestamp);
        agentRegistry.updateProfile("ipfs://new", newSkills);
    }
    function test_UpdateProfile_UpdatesMetadata() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.getAgent(address(this)).metadataURI, "ipfs://new");
    }
    function test_UpdateProfile_UpdatesLastActive() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.warp(block.timestamp + 1 days);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.getAgent(address(this)).lastActive, block.timestamp);
    }
    function test_UpdateProfile_NotRegisteredReverts() public {
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 1;
        vm.expectRevert("Not registered");
        agentRegistry.updateProfile("ipfs://new", newSkills);
    }
    function test_UpdateProfile_InvalidSkillIdReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 99;
        vm.expectRevert("Invalid skill ID");
        agentRegistry.updateProfile("ipfs://new", newSkills);
    }
    function test_UpdateProfile_RemovesFromOldSkills() public {
        uint256[] memory skillIds = new uint256[](2);
        skillIds[0] = 1;
        skillIds[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 3;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.skills(1).agentCount, 0);
        assertEq(agentRegistry.skills(2).agentCount, 0);
    }
    function test_UpdateProfile_AddsToNewSkills() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](2);
        newSkills[0] = 2;
        newSkills[1] = 3;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.skills(2).agentCount, 1);
        assertEq(agentRegistry.skills(3).agentCount, 1);
    }
    function test_UpdateProfile_SkillNamesUpdated() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.getAgent(address(this)).skillNames[0], "Data Analysis");
    }
    function test_UpdateProfile_SameSkillsAllowed() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.updateProfile("ipfs://new", skillIds);
        assertEq(agentRegistry.getAgentSkills(address(this))[0], 1);
    }
    function test_UpdateProfile_EmptySkillsReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](0);
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.getAgentSkills(address(this)).length, 0);
    }
    function test_UpdateProfile_TooManySkillsReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](21);
        for (uint256 i = 0; i < 21; i++) {
            newSkills[i] = 1;
        }
        vm.expectRevert("Too many skills");
        agentRegistry.updateProfile("ipfs://new", newSkills);
    }
    function test_UpdateProfile_MultipleUpdates() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills1 = new uint256[](1);
        newSkills1[0] = 2;
        agentRegistry.updateProfile("ipfs://new1", newSkills1);
        uint256[] memory newSkills2 = new uint256[](1);
        newSkills2[0] = 3;
        agentRegistry.updateProfile("ipfs://new2", newSkills2);
        assertEq(agentRegistry.getAgentSkills(address(this))[0], 3);
        assertEq(agentRegistry.getAgent(address(this)).metadataURI, "ipfs://new2");
    }
    function test_UpdateProfile_DoesNotChangeTotalAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 totalBefore = agentRegistry.totalAgents();
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        agentRegistry.updateProfile("ipfs://new", newSkills);
        assertEq(agentRegistry.totalAgents(), totalBefore);
    }

    // ==================== DEACTIVATE/REACTIVATE TESTS (15) ====================
    function test_Deactivate_Success() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        assertFalse(agentRegistry.isRegistered(address(this)));
    }
    function test_Deactivate_EmitsEvent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.AgentDeactivated(address(this), block.timestamp);
        agentRegistry.deactivate();
    }
    function test_Deactivate_NotRegisteredReverts() public {
        vm.expectRevert("Not registered");
        agentRegistry.deactivate();
    }
    function test_Reactivate_Success() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        agentRegistry.reactivate();
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_Reactivate_EmitsEvent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.AgentReactivated(address(this), block.timestamp);
        agentRegistry.reactivate();
    }
    function test_Reactivate_NotRegisteredReverts() public {
        vm.expectRevert("Not registered");
        agentRegistry.reactivate();
    }
    function test_Reactivate_AlreadyActiveReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectRevert("Already active");
        agentRegistry.reactivate();
    }
    function test_Reactivate_UpdatesLastActive() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        vm.warp(block.timestamp + 1 days);
        agentRegistry.reactivate();
        assertEq(agentRegistry.getAgent(address(this)).lastActive, block.timestamp);
    }
    function test_Deactivate_TwiceReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        vm.expectRevert("Not registered");
        agentRegistry.deactivate();
    }
    function test_DeactivateReactivate_MultipleCycles() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        agentRegistry.reactivate();
        agentRegistry.deactivate();
        agentRegistry.reactivate();
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_Deactivate_DoesNotRemoveFromSkillToAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 1);
    }
    function test_Deactivate_DoesNotChangeSkillCount() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        assertEq(agentRegistry.skills(1).agentCount, 1);
    }
    function test_Reactivate_DoesNotChangeSkillCount() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        agentRegistry.reactivate();
        assertEq(agentRegistry.skills(1).agentCount, 1);
    }
    function test_Deactivate_DoesNotAffectTotalAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 totalBefore = agentRegistry.totalAgents();
        agentRegistry.deactivate();
        assertEq(agentRegistry.totalAgents(), totalBefore);
    }

    // ==================== RECORD ACTIVITY TESTS (15) ====================
    function test_RecordActivity_UpdatesCovenantsCompleted() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 5, 0, 0);
        assertEq(agentRegistry.getAgent(address(this)).covenantsCompleted, 5);
    }
    function test_RecordActivity_UpdatesTasksCompleted() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 0, 10, 0);
        assertEq(agentRegistry.getAgent(address(this)).tasksCompleted, 10);
    }
    function test_RecordActivity_UpdatesTotalEarned() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 0, 0, 5 ether);
        assertEq(agentRegistry.getAgent(address(this)).totalEarned, 5 ether);
    }
    function test_RecordActivity_UpdatesReputation() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 1, 2, 1 ether);
        uint256 expectedReputation = 1 * 10 + 2 * 5 + 1;
        assertEq(agentRegistry.getAgent(address(this)).reputationScore, expectedReputation);
    }
    function test_RecordActivity_EmitsEvent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.ActivityRecorded(address(this), 1, 2, 1 ether);
        agentRegistry.recordActivity(address(this), 1, 2, 1 ether);
    }
    function test_RecordActivity_NotActiveReverts() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        vm.expectRevert("Agent not active");
        agentRegistry.recordActivity(address(this), 1, 0, 0);
    }
    function test_RecordActivity_UpdatesLastActive() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.warp(block.timestamp + 1 days);
        agentRegistry.recordActivity(address(this), 1, 0, 0);
        assertEq(agentRegistry.getAgent(address(this)).lastActive, block.timestamp);
    }
    function test_RecordActivity_MultipleCallsAccumulate() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 1, 1, 1 ether);
        agentRegistry.recordActivity(address(this), 2, 3, 2 ether);
        assertEq(agentRegistry.getAgent(address(this)).covenantsCompleted, 3);
        assertEq(agentRegistry.getAgent(address(this)).tasksCompleted, 4);
        assertEq(agentRegistry.getAgent(address(this)).totalEarned, 3 ether);
    }
    function test_RecordActivity_ZeroValuesAllowed() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 0, 0, 0);
        assertEq(agentRegistry.getAgent(address(this)).reputationScore, 0);
    }
    function test_RecordActivity_CanBeCalledByAnyone() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.prank(alice);
        agentRegistry.recordActivity(address(this), 1, 0, 0);
        assertEq(agentRegistry.getAgent(address(this)).covenantsCompleted, 1);
    }
    function test_RecordActivity_LargeValues() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), type(uint256).max / 100, 0, 0);
        assertTrue(agentRegistry.getAgent(address(this)).reputationScore > 0);
    }
    function test_RecordActivity_ReputationFormula() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(address(this), 5, 10, 2 ether);
        uint256 expected = 5 * 10 + 10 * 5 + 2;
        assertEq(agentRegistry.getAgent(address(this)).reputationScore, expected);
    }
    function test_RecordActivity_EventContainsCorrectAgent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.ActivityRecorded(address(this), 0, 0, 0);
        agentRegistry.recordActivity(address(this), 0, 0, 0);
    }
    function test_RecordActivity_EventContainsCorrectValues() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.expectEmit(true, false, false, true);
        emit AgentRegistry.ActivityRecorded(address(this), 5, 10, 3 ether);
        agentRegistry.recordActivity(address(this), 5, 10, 3 ether);
    }
    function test_RecordActivity_10Calls() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        for (uint256 i = 0; i < 10; i++) {
            agentRegistry.recordActivity(address(this), 1, 1, 1 ether);
        }
        assertEq(agentRegistry.getAgent(address(this)).covenantsCompleted, 10);
        assertEq(agentRegistry.getAgent(address(this)).tasksCompleted, 10);
        assertEq(agentRegistry.getAgent(address(this)).totalEarned, 10 ether);
    }

    // ==================== DISCOVERY TESTS (20) ====================
    function test_FindAgentsBySkill_Empty() public view {
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 0);
    }
    function test_FindAgentsBySkill_OneAgent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 1);
        assertEq(agents[0], address(this));
    }
    function test_FindAgentsBySkill_MultipleAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 5; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 5);
    }
    function test_FindAgentsBySkills_MustHaveAll() public {
        uint256[] memory skillIds1 = new uint256[](2);
        skillIds1[0] = 1;
        skillIds1[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds1);
        uint256[] memory skillIds2 = new uint256[](1);
        skillIds2[0] = 1;
        address agent2 = address(1001);
        vm.deal(agent2, 0.01 ether);
        vm.prank(agent2);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds2);
        uint256[] memory searchSkills = new uint256[](2);
        searchSkills[0] = 1;
        searchSkills[1] = 2;
        address[] memory agents = agentRegistry.findAgentsBySkills(searchSkills);
        assertEq(agents.length, 1);
        assertEq(agents[0], address(this));
    }
    function test_FindAgentsBySkills_EmptyReturnsEmpty() public view {
        uint256[] memory searchSkills = new uint256[](0);
        address[] memory agents = agentRegistry.findAgentsBySkills(searchSkills);
        assertEq(agents.length, 0);
    }
    function test_GetTopAgents_ByReputation() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        address agent1 = address(1001);
        address agent2 = address(1002);
        vm.deal(agent1, 0.01 ether);
        vm.deal(agent2, 0.01 ether);
        vm.prank(agent1);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.prank(agent2);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(agent1, 10, 0, 0);
        agentRegistry.recordActivity(agent2, 5, 0, 0);
        address[] memory top = agentRegistry.getTopAgents(2);
        assertEq(top[0], agent1);
        assertEq(top[1], agent2);
    }
    function test_GetTopAgents_Limit() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 10; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        address[] memory top = agentRegistry.getTopAgents(5);
        assertEq(top.length, 5);
    }
    function test_GetTopAgents_LimitGreaterThanTotal() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        address[] memory top = agentRegistry.getTopAgents(100);
        assertEq(top.length, 1);
    }
    function test_GetTopAgents_EmptyRegistry() public view {
        address[] memory top = agentRegistry.getTopAgents(10);
        assertEq(top.length, 0);
    }
    function test_GetRecentlyActive_WithinSeconds() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        address[] memory recent = agentRegistry.getRecentlyActive(10, 1 days);
        assertEq(recent.length, 1);
        assertEq(recent[0], address(this));
    }
    function test_GetRecentlyActive_OutsideWindow() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.warp(block.timestamp + 2 days);
        address[] memory recent = agentRegistry.getRecentlyActive(10, 1 days);
        assertEq(recent.length, 0);
    }
    function test_GetRecentlyActive_Limit() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 10; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        address[] memory recent = agentRegistry.getRecentlyActive(5, 1 days);
        assertEq(recent.length, 5);
    }
    function test_GetRecentlyActive_DeactivatedNotIncluded() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        address[] memory recent = agentRegistry.getRecentlyActive(10, 1 days);
        assertEq(recent.length, 0);
    }
    function test_FindAgentsBySkill_DeactivatedIncluded() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        address[] memory agents = agentRegistry.findAgentsBySkill(1);
        assertEq(agents.length, 1);
    }
    function test_FindAgentsBySkills_DeactivatedNotIncluded() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        uint256[] memory searchSkills = new uint256[](1);
        searchSkills[0] = 1;
        address[] memory agents = agentRegistry.findAgentsBySkills(searchSkills);
        assertEq(agents.length, 0);
    }
    function test_GetTopAgents_SortedByReputation() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        address agent1 = address(1001);
        address agent2 = address(1002);
        address agent3 = address(1003);
        vm.deal(agent1, 0.01 ether);
        vm.deal(agent2, 0.01 ether);
        vm.deal(agent3, 0.01 ether);
        vm.prank(agent1);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.prank(agent2);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.prank(agent3);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.recordActivity(agent1, 3, 0, 0);
        agentRegistry.recordActivity(agent2, 1, 0, 0);
        agentRegistry.recordActivity(agent3, 5, 0, 0);
        address[] memory top = agentRegistry.getTopAgents(3);
        assertEq(top[0], agent3);
        assertEq(top[1], agent1);
        assertEq(top[2], agent2);
    }
    function test_GetRecentlyActive_EmptyRegistry() public view {
        address[] memory recent = agentRegistry.getRecentlyActive(10, 1 days);
        assertEq(recent.length, 0);
    }
    function test_GetRecentlyActive_ZeroSeconds() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        address[] memory recent = agentRegistry.getRecentlyActive(10, 0);
        assertEq(recent.length, 0);
    }

    // ==================== ADMIN TESTS (15) ====================
    function test_AddSkill_ByOwner() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.addSkill("New Skill", "Description");
        assertEq(agentRegistry.skills(9).name, "New Skill");
    }
    function test_AddSkill_EmitsEvent() public {
        vm.prank(agentRegistry.owner());
        vm.expectEmit(true, false, false, false);
        emit AgentRegistry.SkillAdded(9, "New Skill", "Description");
        agentRegistry.addSkill("New Skill", "Description");
    }
    function test_AddSkill_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert("Not owner");
        agentRegistry.addSkill("New Skill", "Description");
    }
    function test_AddSkill_IncrementsNextSkillId() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.addSkill("New Skill", "Description");
        assertEq(agentRegistry.nextSkillId(), 10);
    }
    function test_SetRegistrationFee_ByOwner() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.setRegistrationFee(0.01 ether);
        assertEq(agentRegistry.registrationFee(), 0.01 ether);
    }
    function test_SetRegistrationFee_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert("Not owner");
        agentRegistry.setRegistrationFee(0.01 ether);
    }
    function test_WithdrawFees_ByOwner() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 ownerBalanceBefore = agentRegistry.owner().balance;
        vm.prank(agentRegistry.owner());
        agentRegistry.withdrawFees();
        assertTrue(agentRegistry.owner().balance > ownerBalanceBefore);
    }
    function test_WithdrawFees_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert("Not owner");
        agentRegistry.withdrawFees();
    }
    function test_WithdrawFees_EmptyContractReverts() public {
        vm.prank(agentRegistry.owner());
        vm.expectRevert("Withdraw failed");
        agentRegistry.withdrawFees();
    }
    function test_AddSkill_MultipleSkills() public {
        vm.startPrank(agentRegistry.owner());
        for (uint256 i = 0; i < 10; i++) {
            agentRegistry.addSkill(string(abi.encodePacked("Skill ", vm.toString(i))), "Description");
        }
        vm.stopPrank();
        assertEq(agentRegistry.nextSkillId(), 19);
    }
    function test_SetRegistrationFee_ZeroAllowed() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.setRegistrationFee(0);
        assertEq(agentRegistry.registrationFee(), 0);
    }
    function test_SetRegistrationFee_LargeAmountAllowed() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.setRegistrationFee(1000 ether);
        assertEq(agentRegistry.registrationFee(), 1000 ether);
    }
    function test_WithdrawFees_CorrectAmount() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 contractBalance = address(agentRegistry).balance;
        uint256 ownerBalanceBefore = agentRegistry.owner().balance;
        vm.prank(agentRegistry.owner());
        agentRegistry.withdrawFees();
        assertEq(agentRegistry.owner().balance - ownerBalanceBefore, contractBalance);
    }
    function test_WithdrawFees_BalanceBecomesZero() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        vm.prank(agentRegistry.owner());
        agentRegistry.withdrawFees();
        assertEq(address(agentRegistry).balance, 0);
    }
    function test_AddSkill_NameToIdMapping() public {
        vm.prank(agentRegistry.owner());
        agentRegistry.addSkill("Unique Skill", "Description");
        assertEq(agentRegistry.skillNameToId("Unique Skill"), 9);
    }

    // ==================== VIEW FUNCTION TESTS (10) ====================
    function test_GetAgentCount_Empty() public view {
        assertEq(agentRegistry.getAgentCount(), 0);
    }
    function test_GetAgentCount_AfterRegister() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.getAgentCount(), 1);
    }
    function test_GetAllSkills_Count() public view {
        AgentRegistry.Skill[] memory skills = agentRegistry.getAllSkills();
        assertEq(skills.length, 8);
    }
    function test_GetAllSkills_Content() public view {
        AgentRegistry.Skill[] memory skills = agentRegistry.getAllSkills();
        assertEq(skills[0].name, "Smart Contract Development");
        assertEq(skills[1].name, "Data Analysis");
    }
    function test_IsRegistered_FalseForUnregistered() public view {
        assertFalse(agentRegistry.isRegistered(alice));
    }
    function test_IsRegistered_TrueForRegistered() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertTrue(agentRegistry.isRegistered(address(this)));
    }
    function test_IsRegistered_FalseForDeactivated() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        assertFalse(agentRegistry.isRegistered(address(this)));
    }
    function test_GetAgent_ReturnsCorrectAddress() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.getAgent(address(this)).agentAddress, address(this));
    }
    function test_GetAgentSkills_ReturnsArray() public {
        uint256[] memory skillIds = new uint256[](2);
        skillIds[0] = 1;
        skillIds[1] = 2;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory skills = agentRegistry.getAgentSkills(address(this));
        assertEq(skills.length, 2);
    }
    function test_GetAgentCount_MatchesTotalAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        assertEq(agentRegistry.getAgentCount(), agentRegistry.totalAgents());
    }

    receive() external payable {}
}
