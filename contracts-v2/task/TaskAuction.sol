// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskAuction} from "../interfaces/ITaskAuction.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TaskAuction
 * @notice Dutch auction mechanism for tasks
 */
contract TaskAuction is ITaskAuction, Ownable, ReentrancyGuard {
    uint256 private _nextAuctionId;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => bool) public taskHasAuction;

    constructor() Ownable(msg.sender) {
        _nextAuctionId = 1;
    }

    /// @inheritdoc ITaskAuction
    function createAuction(
        uint256 taskId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) external returns (uint256 auctionId) {
        if (taskHasAuction[taskId]) revert AuctionNotActive();
        if (startPrice <= endPrice || duration == 0) revert AuctionNotActive();

        auctionId = _nextAuctionId++;
        auctions[auctionId] = Auction({
            taskId: taskId,
            startPrice: startPrice,
            endPrice: endPrice,
            startTime: block.timestamp,
            duration: duration,
            highestBidder: address(0),
            highestBid: 0,
            settled: false
        });
        taskHasAuction[taskId] = true;

        emit AuctionCreated(auctionId, taskId, startPrice, endPrice);
    }

    /// @inheritdoc ITaskAuction
    function placeBid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp > auction.startTime + auction.duration) revert AuctionNotActive();
        if (auction.settled) revert AlreadySettled();

        uint256 currentPrice = getCurrentPrice(auctionId);
        if (msg.value < currentPrice) revert BidTooLow();
        if (msg.value <= auction.highestBid) revert BidTooLow();

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            if (!success) revert AuctionNotActive();
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /// @inheritdoc ITaskAuction
    function settleAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp <= auction.startTime + auction.duration) revert AuctionNotEnded();
        if (auction.settled) revert AlreadySettled();

        auction.settled = true;

        emit AuctionSettled(auctionId, auction.highestBidder, auction.highestBid);
    }

    /// @inheritdoc ITaskAuction
    function cancelAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (auction.settled) revert AlreadySettled();
        if (msg.sender != owner()) revert UnauthorizedCancellation();

        auction.settled = true;
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            if (!success) revert AuctionNotActive();
        }

        emit AuctionCancelled(auctionId);
    }

    /// @inheritdoc ITaskAuction
    function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
        Auction storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();

        uint256 elapsed = block.timestamp - auction.startTime;
        if (elapsed >= auction.duration) return auction.endPrice;

        uint256 priceDrop = ((auction.startPrice - auction.endPrice) * elapsed) / auction.duration;
        return auction.startPrice - priceDrop;
    }

    /// @inheritdoc ITaskAuction
    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    receive() external payable {}
}