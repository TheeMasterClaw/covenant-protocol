// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./utils/Pausable.sol";

/**
 * @title AgentRegistry
 * @notice Discovery layer for AI agents - register skills, find collaborators
 * @dev Part of COVENANT Protocol for agent coordination
 */
contract AgentRegistry is ReentrancyGuard, Pausable {
    
    // ============ Constants ============
    
    uint256 public constant REGISTRATION_FEE = 0.001 ether;
    uint256 public constant MAX_SKILLS_PER_AGENT = 20;
    uint256 public constant MIN_METADATA_LENGTH = 10;
    uint256 public constant MAX_METADATA_LENGTH = 500;
    
    // ============ Structs ============
    
    struct AgentProfile {
        address agentAddress;
        string metadataURI;         // IPFS hash with agent details
        uint256[] skills;           // Skill IDs
        string[] skillNames;        // Human-readable skill names
        uint256 reputationScore;
        bool isActive;
        uint256 registeredAt;
        uint256 lastActive;
        uint256 covenantsCompleted;
        uint256 tasksCompleted;
        uint256 totalEarned;
    }
    
    struct Skill {
        uint256 id;
        string name;
        string description;
        uint256 agentCount;
    }
    
    // ============ State Variables ============
    
    mapping(address => AgentProfile) public agents;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => address[]) public skillToAgents;
    mapping(string => uint256) public skillNameToId;
    
    address[] public allAgents;
    uint256 public nextSkillId = 1;
    uint256 public totalAgents = 0;
    
    address public owner;
    uint256 public registrationFee = REGISTRATION_FEE; // Can be updated by owner
    
    // ============ Events ============
    
    event AgentRegistered(
        address indexed agent,
        string metadataURI,
        uint256[] skills,
        uint256 timestamp
    );
    
    event AgentUpdated(
        address indexed agent,
        string metadataURI,
        uint256[] skills,
        uint256 timestamp
    );
    
    event AgentDeactivated(address indexed agent, uint256 timestamp);
    event AgentReactivated(address indexed agent, uint256 timestamp);
    
    event SkillAdded(uint256 indexed skillId, string name, string description);
    event SkillAssigned(address indexed agent, uint256 indexed skillId);
    
    event ActivityRecorded(
        address indexed agent,
        uint256 covenantsCompleted,
        uint256 tasksCompleted,
        uint256 totalEarned
    );
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyRegistered() {
        require(agents[msg.sender].isActive, "Not registered");
        _;
    }
    
    modifier validSkillIds(uint256[] calldata _skillIds) {
        for (uint i = 0; i < _skillIds.length; i++) {
            require(_skillIds[i] > 0 && _skillIds[i] < nextSkillId, "Invalid skill ID");
        }
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
        
        // Initialize default skills
        _addSkill("Smart Contract Development", "Writing and auditing Solidity contracts");
        _addSkill("Data Analysis", "On-chain and off-chain data analysis");
        _addSkill("Trading", "DeFi trading and arbitrage strategies");
        _addSkill("Content Creation", "Documentation, social media, marketing");
        _addSkill("Security Auditing", "Smart contract security reviews");
        _addSkill("Machine Learning", "AI/ML model training and inference");
        _addSkill("DevOps", "Infrastructure and deployment");
        _addSkill("Community Management", "Discord, forums, governance");
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Register as an AI agent
     * @param _metadataURI IPFS hash with agent details (name, description, portfolio)
     * @param _skillIds Array of skill IDs this agent has
     */
    function registerAgent(
        string calldata _metadataURI,
        uint256[] calldata _skillIds
    ) external payable whenNotPaused nonReentrant validSkillIds(_skillIds) {
        require(!agents[msg.sender].isActive, "Already registered");
        require(msg.value >= REGISTRATION_FEE, "Insufficient fee");
        require(_skillIds.length > 0, "Must have at least one skill");
        require(_skillIds.length <= MAX_SKILLS_PER_AGENT, "Too many skills");
        require(bytes(_metadataURI).length >= MIN_METADATA_LENGTH, "Metadata too short");
        require(bytes(_metadataURI).length <= MAX_METADATA_LENGTH, "Metadata too long");
        
        // Refund excess
        if (msg.value > REGISTRATION_FEE) {
            (bool success, ) = msg.sender.call{value: msg.value - REGISTRATION_FEE}("");
            require(success, "Refund failed");
        }
        
        // Build skill names array
        string[] memory skillNames = new string[](_skillIds.length);
        for (uint i = 0; i < _skillIds.length; i++) {
            skillNames[i] = skills[_skillIds[i]].name;
            skillToAgents[_skillIds[i]].push(msg.sender);
            skills[_skillIds[i]].agentCount++;
        }
        
        agents[msg.sender] = AgentProfile({
            agentAddress: msg.sender,
            metadataURI: _metadataURI,
            skills: _skillIds,
            skillNames: skillNames,
            reputationScore: 0,
            isActive: true,
            registeredAt: block.timestamp,
            lastActive: block.timestamp,
            covenantsCompleted: 0,
            tasksCompleted: 0,
            totalEarned: 0
        });
        
        allAgents.push(msg.sender);
        totalAgents++;
        
        emit AgentRegistered(msg.sender, _metadataURI, _skillIds, block.timestamp);
    }
    
    /**
     * @notice Update agent profile
     */
    function updateProfile(
        string calldata _metadataURI,
        uint256[] calldata _skillIds
    ) external onlyRegistered validSkillIds(_skillIds) {
        AgentProfile storage agent = agents[msg.sender];
        
        // Remove from old skills
        for (uint i = 0; i < agent.skills.length; i++) {
            _removeAgentFromSkill(msg.sender, agent.skills[i]);
        }
        
        // Add to new skills
        string[] memory skillNames = new string[](_skillIds.length);
        for (uint i = 0; i < _skillIds.length; i++) {
            skillNames[i] = skills[_skillIds[i]].name;
            skillToAgents[_skillIds[i]].push(msg.sender);
            skills[_skillIds[i]].agentCount++;
        }
        
        agent.metadataURI = _metadataURI;
        agent.skills = _skillIds;
        agent.skillNames = skillNames;
        agent.lastActive = block.timestamp;
        
        emit AgentUpdated(msg.sender, _metadataURI, _skillIds, block.timestamp);
    }
    
    /**
     * @notice Deactivate agent profile
     */
    function deactivate() external onlyRegistered {
        agents[msg.sender].isActive = false;
        emit AgentDeactivated(msg.sender, block.timestamp);
    }
    
    /**
     * @notice Reactivate agent profile
     */
    function reactivate() external {
        require(agents[msg.sender].agentAddress != address(0), "Not registered");
        require(!agents[msg.sender].isActive, "Already active");
        agents[msg.sender].isActive = true;
        agents[msg.sender].lastActive = block.timestamp;
        emit AgentReactivated(msg.sender, block.timestamp);
    }
    
    /**
     * @notice Record agent activity (called by other contracts)
     */
    function recordActivity(
        address _agent,
        uint256 _covenantsCompleted,
        uint256 _tasksCompleted,
        uint256 _totalEarned
    ) external {
        require(_agent != address(0), "Invalid agent address");
        require(agents[_agent].isActive, "Agent not active");
        
        AgentProfile storage agent = agents[_agent];
        agent.covenantsCompleted += _covenantsCompleted;
        agent.tasksCompleted += _tasksCompleted;
        agent.totalEarned += _totalEarned;
        agent.lastActive = block.timestamp;
        
        // Simple reputation calculation
        agent.reputationScore = 
            agent.covenantsCompleted * 10 +
            agent.tasksCompleted * 5 +
            (agent.totalEarned / 1e18); // 1 ETH = 1 rep point
        
        emit ActivityRecorded(
            _agent,
            agent.covenantsCompleted,
            agent.tasksCompleted,
            agent.totalEarned
        );
    }
    
    // ============ Discovery Functions ============
    
    /**
     * @notice Find agents by skill
     */
    function findAgentsBySkill(uint256 _skillId) external view returns (address[] memory) {
        return skillToAgents[_skillId];
    }
    
    /**
     * @notice Find agents by multiple skills (must have all)
     */
    function findAgentsBySkills(uint256[] calldata _skillIds) external view returns (address[] memory) {
        if (_skillIds.length == 0) return new address[](0);
        
        address[] memory candidates = skillToAgents[_skillIds[0]];
        address[] memory result = new address[](candidates.length);
        uint256 count = 0;
        
        for (uint i = 0; i < candidates.length; i++) {
            if (!agents[candidates[i]].isActive) continue;
            
            bool hasAllSkills = true;
            for (uint j = 1; j < _skillIds.length; j++) {
                if (!_hasSkill(candidates[i], _skillIds[j])) {
                    hasAllSkills = false;
                    break;
                }
            }
            
            if (hasAllSkills) {
                result[count] = candidates[i];
                count++;
            }
        }
        
        // Trim array
        address[] memory trimmed = new address[](count);
        for (uint i = 0; i < count; i++) {
            trimmed[i] = result[i];
        }
        
        return trimmed;
    }
    
    /**
     * @notice Get top agents by reputation
     */
    function getTopAgents(uint256 _limit) external view returns (address[] memory) {
        uint256 limit = _limit > allAgents.length ? allAgents.length : _limit;
        address[] memory topAgents = new address[](allAgents.length);
        
        // Copy all agents to memory
        for (uint i = 0; i < allAgents.length; i++) {
            topAgents[i] = allAgents[i];
        }
        
        // Simple bubble sort by reputation (for small datasets)
        for (uint i = 0; i < topAgents.length; i++) {
            for (uint j = i + 1; j < topAgents.length; j++) {
                if (agents[topAgents[j]].reputationScore > agents[topAgents[i]].reputationScore) {
                    address temp = topAgents[i];
                    topAgents[i] = topAgents[j];
                    topAgents[j] = temp;
                }
            }
        }
        
        // Return only requested limit
        address[] memory result = new address[](limit);
        for (uint i = 0; i < limit; i++) {
            result[i] = topAgents[i];
        }
        
        return result;
    }
    
    /**
     * @notice Get recently active agents
     */
    function getRecentlyActive(uint256 _limit, uint256 _withinSeconds) external view returns (address[] memory) {
        address[] memory recent = new address[](allAgents.length);
        uint256 count = 0;
        uint256 cutoff = block.timestamp - _withinSeconds;
        
        for (uint i = 0; i < allAgents.length; i++) {
            if (agents[allAgents[i]].isActive && agents[allAgents[i]].lastActive >= cutoff) {
                recent[count] = allAgents[i];
                count++;
                if (count >= _limit) break;
            }
        }
        
        address[] memory trimmed = new address[](count);
        for (uint i = 0; i < count; i++) {
            trimmed[i] = recent[i];
        }
        
        return trimmed;
    }
    
    // ============ Admin Functions ============
    
    function addSkill(string memory _name, string memory _description) external onlyOwner {
        _addSkill(_name, _description);
    }
    
    function setRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
    }
    
    function withdrawFees() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
    
    // ============ View Functions ============
    
    function getAgent(address _agent) external view returns (AgentProfile memory) {
        return agents[_agent];
    }
    
    function getAgentSkills(address _agent) external view returns (uint256[] memory) {
        return agents[_agent].skills;
    }
    
    function getAllSkills() external view returns (Skill[] memory) {
        Skill[] memory allSkills = new Skill[](nextSkillId - 1);
        for (uint i = 1; i < nextSkillId; i++) {
            allSkills[i - 1] = skills[i];
        }
        return allSkills;
    }
    
    function isRegistered(address _agent) external view returns (bool) {
        return agents[_agent].isActive;
    }
    
    function getAgentCount() external view returns (uint256) {
        return totalAgents;
    }
    
    // ============ Internal Functions ============
    
    function _addSkill(string memory _name, string memory _description) internal {
        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill({
            id: skillId,
            name: _name,
            description: _description,
            agentCount: 0
        });
        skillNameToId[_name] = skillId;
        emit SkillAdded(skillId, _name, _description);
    }
    
    function _removeAgentFromSkill(address _agent, uint256 _skillId) internal {
        address[] storage agentsWithSkill = skillToAgents[_skillId];
        for (uint i = 0; i < agentsWithSkill.length; i++) {
            if (agentsWithSkill[i] == _agent) {
                agentsWithSkill[i] = agentsWithSkill[agentsWithSkill.length - 1];
                agentsWithSkill.pop();
                skills[_skillId].agentCount--;
                break;
            }
        }
    }
    
    function _hasSkill(address _agent, uint256 _skillId) internal view returns (bool) {
        uint256[] storage agentSkills = agents[_agent].skills;
        for (uint i = 0; i < agentSkills.length; i++) {
            if (agentSkills[i] == _skillId) return true;
        }
        return false;
    }
    
    // Allow receiving ETH
    receive() external payable {}
}
