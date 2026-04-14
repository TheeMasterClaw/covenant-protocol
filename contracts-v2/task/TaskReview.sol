// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskReview} from "../interfaces/ITaskReview.sol";
import {IReputationOracle} from "../interfaces/IReputationOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaskReview
 * @notice Quality assurance via task reviews with multi-oracle verification integration.
 *         Supports Chainlink Functions, UMA OO, API3, Pyth, Tellor, and Reclaim Protocol.
 */
contract TaskReview is ITaskReview, Ownable {
    uint256 private _nextReviewId;
    mapping(uint256 => Review) public reviews;
    mapping(uint256 => uint256[]) public reviewsByTask;
    mapping(address => uint256[]) public reviewsByReviewee;
    mapping(uint256 => mapping(address => bool)) public hasReviewed;
    mapping(uint256 => TaskDeliverable) public taskDeliverables;

    IReputationOracle public reputationOracle;

    // Task-specific oracle requirements
    mapping(uint256 => uint8) public requiredConfidenceForTask;
    mapping(uint256 => bool) public requiresMultiOracleVerification;

    constructor(address reputationOracleAddress) Ownable(msg.sender) {
        _nextReviewId = 1;
        reputationOracle = IReputationOracle(reputationOracleAddress);
    }

    /// @inheritdoc ITaskReview
    function submitDeliverable(uint256 taskId, bytes32 contentHash) external {
        if (contentHash == bytes32(0)) revert InvalidDeliverable();
        if (taskDeliverables[taskId].agent != address(0)) revert DeliverableAlreadySubmitted();

        taskDeliverables[taskId] = TaskDeliverable({
            taskId: taskId,
            agent: msg.sender,
            contentHash: contentHash,
            verificationSources: new IReputationOracle.OracleType[](0),
            aggregatedConfidence: 0,
            fullyVerified: false
        });

        emit DeliverableSubmitted(taskId, msg.sender, contentHash);
    }

    /**
     * @notice Mark a deliverable as verified by a specific oracle source
     * @param taskId Task to verify
     * @param oracleDataHash Hash of oracle verification data in ReputationOracle
     */
    function markDeliverableVerified(uint256 taskId, IReputationOracle.OracleType oracleType, uint8 confidence, bytes32 oracleDataHash) external {
        TaskDeliverable storage deliverable = taskDeliverables[taskId];
        if (deliverable.agent == address(0)) revert InvalidDeliverable();

        IReputationOracle.OracleData memory data = reputationOracle.getData(oracleDataHash);
        if (data.timestamp == 0) revert InvalidDeliverable();
        if (data.confidence < requiredConfidenceForTask[taskId]) revert OracleVerificationRequired();

        // Update verification sources
        IReputationOracle.OracleType[] storage sources = deliverable.verificationSources;
        bool alreadyVerifiedByType;
        for (uint256 i = 0; i < sources.length; ) {
            if (sources[i] == oracleType) {
                alreadyVerifiedByType = true;
                break;
            }
            unchecked { ++i; }
        }

        if (!alreadyVerifiedByType) {
            sources.push(oracleType);
        }

        // Update aggregated confidence as weighted average
        uint256 currentCount = sources.length;
        if (currentCount == 1) {
            deliverable.aggregatedConfidence = confidence;
        } else {
            deliverable.aggregatedConfidence = ((deliverable.aggregatedConfidence * (currentCount - 1)) + confidence) / currentCount;
        }

        // Check multi-oracle requirement
        bool multiOracle = requiresMultiOracleVerification[taskId];
        (bool verified,,) = reputationOracle.getTaskVerificationStatus(taskId);
        deliverable.fullyVerified = multiOracle ? verified : (confidence >= requiredConfidenceForTask[taskId]);

        emit DeliverableVerified(taskId, oracleType, confidence);
    }

    /// @inheritdoc ITaskReview
    function submitReview(
        uint256 taskId,
        address reviewee,
        uint8 rating,
        bytes32 commentHash
    ) external returns (uint256 reviewId) {
        if (rating == 0 || rating > 5) revert InvalidRating();
        if (reviewee == address(0)) revert UnauthorizedReviewer();
        if (hasReviewed[taskId][msg.sender]) revert ReviewAlreadyExists();

        // Optional: require deliverable verification before review
        TaskDeliverable memory deliverable = taskDeliverables[taskId];
        if (deliverable.agent != address(0) && !deliverable.fullyVerified) {
            revert OracleVerificationRequired();
        }

        reviewId = _nextReviewId++;
        reviews[reviewId] = Review({
            reviewId: reviewId,
            taskId: taskId,
            reviewer: msg.sender,
            reviewee: reviewee,
            rating: rating,
            commentHash: commentHash,
            createdAt: block.timestamp,
            status: deliverable.fullyVerified ? ReviewStatus.OracleVerified : ReviewStatus.Pending,
            oracleDataHash: bytes32(0)
        });

        reviewsByTask[taskId].push(reviewId);
        reviewsByReviewee[reviewee].push(reviewId);
        hasReviewed[taskId][msg.sender] = true;

        emit ReviewSubmitted(reviewId, taskId, msg.sender, rating);
    }

    /// @inheritdoc ITaskReview
    function submitOracleReview(
        uint256 taskId,
        address reviewee,
        uint8 rating,
        bytes32 commentHash,
        bytes32 oracleDataHash
    ) external returns (uint256 reviewId) {
        if (rating == 0 || rating > 5) revert InvalidRating();
        if (reviewee == address(0)) revert UnauthorizedReviewer();
        if (hasReviewed[taskId][msg.sender]) revert ReviewAlreadyExists();

        IReputationOracle.OracleData memory data = reputationOracle.getData(oracleDataHash);
        if (data.timestamp == 0) revert OracleVerificationRequired();

        reviewId = _nextReviewId++;
        reviews[reviewId] = Review({
            reviewId: reviewId,
            taskId: taskId,
            reviewer: msg.sender,
            reviewee: reviewee,
            rating: rating,
            commentHash: commentHash,
            createdAt: block.timestamp,
            status: ReviewStatus.OracleVerified,
            oracleDataHash: oracleDataHash
        });

        reviewsByTask[taskId].push(reviewId);
        reviewsByReviewee[reviewee].push(reviewId);
        hasReviewed[taskId][msg.sender] = true;

        emit ReviewSubmitted(reviewId, taskId, msg.sender, rating);
    }

    /// @inheritdoc ITaskReview
    function updateReview(uint256 reviewId, uint8 newRating, bytes32 newCommentHash) external {
        Review storage review = reviews[reviewId];
        if (review.reviewId == 0) revert UnauthorizedReviewer();
        if (review.reviewer != msg.sender) revert UnauthorizedReviewer();
        if (newRating == 0 || newRating > 5) revert InvalidRating();

        review.rating = newRating;
        review.commentHash = newCommentHash;

        emit ReviewUpdated(reviewId, newRating);
    }

    /**
     * @notice Update review status (e.g., after dispute resolution)
     */
    function setReviewStatus(uint256 reviewId, ReviewStatus status) external onlyOwner {
        Review storage review = reviews[reviewId];
        if (review.reviewId == 0) revert UnauthorizedReviewer();
        review.status = status;
        emit ReviewStatusChanged(reviewId, status);
    }

    /// @inheritdoc ITaskReview
    function getReview(uint256 reviewId) external view returns (Review memory) {
        return reviews[reviewId];
    }

    /// @inheritdoc ITaskReview
    function getReviewsByTask(uint256 taskId) external view returns (uint256[] memory) {
        return reviewsByTask[taskId];
    }

    /// @inheritdoc ITaskReview
    function getReviewsByReviewee(address reviewee) external view returns (uint256[] memory) {
        return reviewsByReviewee[reviewee];
    }

    /// @inheritdoc ITaskReview
    function getAverageRating(address reviewee) external view returns (uint256 average, uint256 count) {
        uint256[] storage revs = reviewsByReviewee[reviewee];
        count = revs.length;
        if (count == 0) return (0, 0);

        uint256 sum;
        for (uint256 i = 0; i < count; ) {
            sum += reviews[revs[i]].rating;
            unchecked {
                ++i;
            }
        }
        average = sum / count;
    }

    /// @inheritdoc ITaskReview
    function getTaskDeliverable(uint256 taskId) external view returns (TaskDeliverable memory) {
        return taskDeliverables[taskId];
    }

    // Admin functions
    function setReputationOracle(address newOracle) external onlyOwner {
        reputationOracle = IReputationOracle(newOracle);
    }

    function setTaskRequirements(uint256 taskId, uint8 confidence, bool multiOracle) external onlyOwner {
        requiredConfidenceForTask[taskId] = confidence;
        requiresMultiOracleVerification[taskId] = multiOracle;
    }
}
