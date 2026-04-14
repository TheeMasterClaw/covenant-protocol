// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AgentRegistry
 * @notice Core on-chain registry for AI agent identities across frameworks
 */
contract AgentRegistry is Ownable {
    enum Platform {
        NONE,
        ELIZA,
        OLAS,
        FETCH,
        BITTENSOR,
        MORPHEUS,
        CUSTOM
    }

    struct Agent {
        address owner;
        bytes32[] capabilities;
        string metadataURI;
        bool active;
        uint256 registeredAt;
        uint256 reputationScore;
    }

    struct ExternalIdentity {
        Platform platform;
        bytes externalId;
        bool verified;
    }

    uint256 private _nextAgentId;
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => ExternalIdentity[]) public agentIdentities;
    mapping(address => uint256[]) public agentsByOwner;
    mapping(bytes32 => uint256[]) public agentsByCapability;

    event AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event IdentityLinked(uint256 indexed agentId, Platform platform, bytes externalId);
    event IdentityVerified(uint256 indexed agentId, Platform platform);
    event AgentActivated(uint256 indexed agentId);
    event AgentDeactivated(uint256 indexed agentId);
    event CapabilityAdded(uint256 indexed agentId, bytes32 capability);
    event ReputationUpdated(uint256 indexed agentId, uint256 newScore);

    error InvalidAgent();
    error Unauthorized();
    error AlreadyRegistered();

    constructor() Ownable(msg.sender) {
        _nextAgentId = 1;
    }

    function registerAgent(
        address owner,
        bytes32[] calldata capabilities,
        string calldata metadataURI
    ) external returns (uint256 agentId) {
        agentId = _nextAgentId++;
        agents[agentId] = Agent({
            owner: owner,
            capabilities: capabilities,
            metadataURI: metadataURI,
            active: true,
            registeredAt: block.timestamp,
            reputationScore: 0
        });
        agentsByOwner[owner].push(agentId);
        for (uint256 i = 0; i < capabilities.length; i++) {
            agentsByCapability[capabilities[i]].push(agentId);
        }
        emit AgentRegistered(agentId, owner, metadataURI);
    }

    function linkExternalIdentity(
        uint256 agentId,
        Platform platform,
        bytes calldata externalId
    ) external {
        Agent storage agent = agents[agentId];
        if (agent.owner == address(0)) revert InvalidAgent();
        if (msg.sender != agent.owner && msg.sender != owner()) revert Unauthorized();

        agentIdentities[agentId].push(ExternalIdentity(platform, externalId, false));
        emit IdentityLinked(agentId, platform, externalId);
    }

    function verifyIdentity(uint256 agentId, uint256 identityIndex) external onlyOwner {
        ExternalIdentity storage identity = agentIdentities[agentId][identityIndex];
        identity.verified = true;
        emit IdentityVerified(agentId, identity.platform);
    }

    function addCapability(uint256 agentId, bytes32 capability) external {
        Agent storage agent = agents[agentId];
        if (msg.sender != agent.owner && msg.sender != owner()) revert Unauthorized();
        agent.capabilities.push(capability);
        agentsByCapability[capability].push(agentId);
        emit CapabilityAdded(agentId, capability);
    }

    function setActive(uint256 agentId, bool active) external {
        Agent storage agent = agents[agentId];
        if (msg.sender != agent.owner && msg.sender != owner()) revert Unauthorized();
        agent.active = active;
        if (active) emit AgentActivated(agentId);
        else emit AgentDeactivated(agentId);
    }

    function updateReputation(uint256 agentId, uint256 newScore) external onlyOwner {
        agents[agentId].reputationScore = newScore;
        emit ReputationUpdated(agentId, newScore);
    }

    function getAgent(uint256 agentId) external view returns (Agent memory) {
        return agents[agentId];
    }

    function getIdentities(uint256 agentId) external view returns (ExternalIdentity[] memory) {
        return agentIdentities[agentId];
    }

    function getAgentsByOwner(address ownerAddr) external view returns (uint256[] memory) {
        return agentsByOwner[ownerAddr];
    }

    function getAgentsByCapability(bytes32 capability) external view returns (uint256[] memory) {
        return agentsByCapability[capability];
    }
}
