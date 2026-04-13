// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskReview} from "../interfaces/ITaskReview.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaskReview
 * @notice Quality assurance via task reviews
 */
contract TaskReview is ITaskReview, Ownable {
    uint256 private _nextReviewId;
    mapping(uint256 => Review) public reviews;
    mapping(uint256 => uint256[]) public reviewsByTask;
    mapping(address => uint256[]) public reviewsByReviewee;
    mapping(uint256 => mapping(address => bool)) public hasReviewed;

    constructor() Ownable(msg.sender) {
        _nextReviewId = 1;
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

        reviewId = _nextReviewId++;
        reviews[reviewId] = Review({
            reviewId: reviewId,
            taskId: taskId,
            reviewer: msg.sender,
            reviewee: reviewee,
            rating: rating,
            commentHash: commentHash,
            createdAt: block.timestamp
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
}
