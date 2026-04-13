// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITaskReview
 * @notice Interface for the TaskReview contract
 */
interface ITaskReview {
    struct Review {
        uint256 reviewId;
        uint256 taskId;
        address reviewer;
        address reviewee;
        uint8 rating; // 1-5
        bytes32 commentHash;
        uint256 createdAt;
    }

    event ReviewSubmitted(uint256 indexed reviewId, uint256 indexed taskId, address indexed reviewer, uint8 rating);
    event ReviewUpdated(uint256 indexed reviewId, uint8 newRating);

    error InvalidRating();
    error ReviewAlreadyExists();
    error TaskNotCompleted();
    error UnauthorizedReviewer();

    function submitReview(uint256 taskId, address reviewee, uint8 rating, bytes32 commentHash) external returns (uint256 reviewId);
    function updateReview(uint256 reviewId, uint8 newRating, bytes32 newCommentHash) external;
    function getReview(uint256 reviewId) external view returns (Review memory);
    function getReviewsByTask(uint256 taskId) external view returns (uint256[] memory);
    function getReviewsByReviewee(address reviewee) external view returns (uint256[] memory);
    function getAverageRating(address reviewee) external view returns (uint256 average, uint256 count);
}
