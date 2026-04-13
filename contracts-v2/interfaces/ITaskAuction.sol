// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITaskAuction
 * @notice Interface for the TaskAuction contract
 */
interface ITaskAuction {
    struct Auction {
        uint256 taskId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
        address highestBidder;
        uint256 highestBid;
        bool settled;
    }

    event AuctionCreated(uint256 indexed auctionId, uint256 indexed taskId, uint256 startPrice, uint256 endPrice);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId);

    error AuctionNotFound();
    error AuctionNotActive();
    error BidTooLow();
    error AuctionNotEnded();
    error AlreadySettled();
    error UnauthorizedCancellation();

    function createAuction(
        uint256 taskId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) external returns (uint256 auctionId);

    function placeBid(uint256 auctionId) external payable;
    function settleAuction(uint256 auctionId) external;
    function cancelAuction(uint256 auctionId) external;
    function getCurrentPrice(uint256 auctionId) external view returns (uint256);
    function getAuction(uint256 auctionId) external view returns (Auction memory);
}
