// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationStake
 * @notice Interface for ReputationStake contract
 */
interface IReputationStake {
    struct Stake {
        uint256 amount;
        uint256 since;
        uint256 unlockTime;
        bool withdrawn;
    }

    struct AgentProfile {
        uint256 totalStaked;
        uint256 reputationScore;
        uint256 successfulCovenants;
        uint256 breachedCovenants;
        uint256 lastActivity;
        bool isActive;
        string metadataURI;
    }

    // State variables
    function stakeToken() external view returns (address);
    function feeRecipient() external view returns (address);
    function agents(address _agent) external view returns (AgentProfile memory);
    function agentStakes(address _agent, uint256 _index) external view returns (Stake memory);
    function authorizedSlashers(address _addr) external view returns (bool);
    function minimumStake() external view returns (uint256);
    function slashingPercentage() external view returns (uint256);
    function lockPeriod() external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function totalAgents() external view returns (uint256);

    // Core functions
    function registerAgent(string calldata _metadataURI) external;
    function stake(uint256 _amount) external;
    function withdrawStake(uint256 _stakeIndex) external;
    function recordSuccess(address _agent) external;
    function recordBreach(address _agent, uint256 _slashingMultiplier, string calldata _reason) external;
    function calculateReputation(address _agent) external view returns (uint256);

    // View functions
    function getStakeCount(address _agent) external view returns (uint256);
    function getStake(address _agent, uint256 _index) external view returns (Stake memory);
    function getAgentProfile(address _agent) external view returns (AgentProfile memory);
    function isRegistered(address _agent) external view returns (bool);
}
