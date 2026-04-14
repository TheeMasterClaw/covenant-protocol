// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "./IReputationOracle.sol";

/**
 * @title ITaskReview
 * @notice Interface for the TaskReview contract with oracle integration
 */
interface ITaskReview {
    enum ReviewStatus {
        Pending,
        OracleVerified,
        Disputed,
        Resolved
    }

    struct Review {
        uint256 reviewId;
        uint256 taskId;
        address reviewer;
        address reviewee;
        uint8 rating; // 1-5
        bytes32 commentHash;
        uint256 createdAt;
        ReviewStatus status;
        bytes32 oracleDataHash; // Link to ReputationOracle verification
    }

    struct TaskDeliverable {
        uint256 taskId;
        address agent;
        bytes32 contentHash; // IPFS or content hash
        IReputationOracle.OracleType[] verificationSources;
        uint256 aggregatedConfidence;
        bool fullyVerified;
    }

    event ReviewSubmitted(uint256 indexed reviewId, uint256 indexed taskId, address indexed reviewer, uint8 rating);
    event ReviewUpdated(uint256 indexed reviewId, uint8 newRating);
    event DeliverableSubmitted(uint256 indexed taskId, address indexed agent, bytes32 contentHash);
    event DeliverableVerified(uint256 indexed taskId, IReputationOracle.OracleType indexed oracleType, uint8 confidence);
    event ReviewStatusChanged(uint256 indexed reviewId, ReviewStatus newStatus);

    error InvalidRating();
    error ReviewAlreadyExists();
    error TaskNotCompleted();
    error UnauthorizedReviewer();
    error UnauthorizedAgent();
    error DeliverableAlreadySubmitted();
    error OracleVerificationRequired();
    error InvalidDeliverable();

    function submitReview(uint256 taskId, address reviewee, uint8 rating, bytes32 commentHash) external returns (uint256 reviewId);
    function submitOracleReview(uint256 taskId, address reviewee, uint8 rating, bytes32 commentHash, bytes32 oracleDataHash) external returns (uint256 reviewId);
    function updateReview(uint256 reviewId, uint8 newRating, bytes32 newCommentHash) external;
    function submitDeliverable(uint256 taskId, bytes32 contentHash) external;
    function markDeliverableVerified(uint256 taskId, IReputationOracle.OracleType oracleType, uint8 confidence, bytes32 oracleDataHash) external;
    function getReview(uint256 reviewId) external view returns (Review memory);
    function getReviewsByTask(uint256 taskId) external view returns (uint256[] memory);
    function getReviewsByReviewee(address reviewee) external view returns (uint256[] memory);
    function getAverageRating(address reviewee) external view returns (uint256 average, uint256 count);
    function getTaskDeliverable(uint256 taskId) external view returns (TaskDeliverable memory);
}
