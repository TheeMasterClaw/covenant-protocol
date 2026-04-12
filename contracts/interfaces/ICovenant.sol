// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenant
 * @notice Interface for AgentCovenant contract
 */
interface ICovenant {
    enum CovenantStatus {
        PENDING,
        ACTIVE,
        FULFILLED,
        DISPUTED,
        RESOLVED,
        EXPIRED,
        BREACHED
    }

    struct CovenantTerms {
        bytes32 covenantType;
        string termsIPFSHash;
        uint256 createdAt;
        uint256 expiresAt;
        uint256 stakeAmount;
    }

    struct Milestone {
        string description;
        uint256 paymentAmount;
        bool completed;
        bool paid;
        uint256 completedAt;
    }

    // State variables
    function initiator() external view returns (address);
    function counterparty() external view returns (address);
    function terms() external view returns (CovenantTerms memory);
    function status() external view returns (CovenantStatus);
    function milestones(uint256 index) external view returns (Milestone memory);
    function remainingBalance() external view returns (uint256);

    // Core functions
    function acceptCovenant() external;
    function addMilestone(string calldata _description, uint256 _paymentAmount) external;
    function completeMilestone(uint256 _milestoneIndex) external;
    function payMilestone(uint256 _milestoneIndex) external;
    function raiseDispute(string calldata _reason) external;
    function resolveDispute(uint256 _initiatorAward, uint256 _counterpartyAward) external;
    function declareBreach(string calldata _reason) external;
    function withdrawRemaining() external;

    // View functions
    function getMilestoneCount() external view returns (uint256);
    function getMilestone(uint256 _index) external view returns (Milestone memory);
    function isActive() external view returns (bool);
    function timeRemaining() external view returns (uint256);
}
