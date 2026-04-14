// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskAuction} from "../contracts-v2/interfaces/ITaskAuction.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TaskAuctionVickrey
 * @notice Sealed-bid Vickrey auction with commit-reveal MEV protection.
 * @dev Replaces Dutch auction with commit/reveal phases. Winner pays second-highest price.
 *      Inspired by Gnosis EasyAuction sealed orders and CoW Protocol batch settlement.
 */
contract TaskAuctionVickrey is ITaskAuction, Ownable, ReentrancyGuard {
    uint256 private _nextAuctionId;

    enum AuctionPhase { PENDING, COMMIT, REVEAL, SETTLED }

    struct SealedBid {
        bytes32 commitment;
        uint256 deposit;
        bool revealed;
    }

    struct RevealedBid {
        address bidder;
        uint256 amount;
        bytes32 salt;
        bool valid;
    }

    struct AuctionData {
        uint256 taskId;
        uint256 startPrice;      // reserve / min price
        uint256 endPrice;        // kept for interface compatibility (acts as minBid)
        uint256 startTime;
        uint256 duration;
        uint256 commitDuration;
        uint256 revealDuration;
        address highestBidder;
        uint256 highestBid;
        uint256 secondHighestBid;
        bool settled;
        AuctionPhase phase;
        uint256 revealedCount;
    }

    mapping(uint256 => AuctionData) public auctions;
    mapping(uint256 => bool) public taskHasAuction;
    mapping(uint256 => mapping(address => SealedBid)) public sealedBids;
    mapping(uint256 => mapping(uint256 => RevealedBid)) public revealedBids;
    mapping(uint256 => uint256) public auctionBalances;

    uint256 public constant MIN_COMMIT_DURATION = 10 minutes;
    uint256 public constant MIN_REVEAL_DURATION = 10 minutes;
    uint256 public constant MAX_BIDS_PER_AUCTION = 200;

    constructor() Ownable(msg.sender) {
        _nextAuctionId = 1;
    }

    // ============ Events ============
    event AuctionCreated(uint256 indexed auctionId, uint256 indexed taskId, uint256 commitEnd, uint256 revealEnd);
    event BidCommitted(uint256 indexed auctionId, address indexed bidder, bytes32 commitment);
    event BidRevealed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed auctionId, address indexed winner, uint256 winningPrice);
    event RefundClaimed(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    // ============ Errors ============
    error AuctionNotFound();
    error AuctionNotActive();
    error BidTooLow();
    error AuctionNotEnded();
    error AlreadySettled();
    error UnauthorizedCancellation();
    error InvalidCommitment();
    error RevealPhaseEnded();
    error CommitPhaseActive();
    error AlreadyRevealed();
    error MaxBidsReached();

    // ============ Modifiers ============
    modifier atPhase(uint256 auctionId, AuctionPhase expected) {
        if (auctions[auctionId].phase != expected) revert AuctionNotActive();
        _;
    }

    // ============ Core Functions ============

    /**
     * @notice Create a new sealed-bid Vickrey auction.
     * @param taskId The task to auction.
     * @param startPrice Minimum acceptable bid (reserve).
     * @param endPrice Kept for interface parity; reused as absolute min bid.
     * @param duration Total auction duration (commit + reveal).
     */
    function createAuction(
        uint256 taskId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) external override returns (uint256 auctionId) {
        if (taskHasAuction[taskId]) revert AuctionNotActive();
        if (startPrice < endPrice || duration < MIN_COMMIT_DURATION + MIN_REVEAL_DURATION) revert AuctionNotActive();

        auctionId = _nextAuctionId++;
        uint256 commitDuration = duration / 2;
        uint256 revealDuration = duration - commitDuration;

        auctions[auctionId] = AuctionData({
            taskId: taskId,
            startPrice: startPrice,
            endPrice: endPrice,
            startTime: block.timestamp,
            duration: duration,
            commitDuration: commitDuration,
            revealDuration: revealDuration,
            highestBidder: address(0),
            highestBid: 0,
            secondHighestBid: 0,
            settled: false,
            phase: AuctionPhase.COMMIT,
            revealedCount: 0
        });
        taskHasAuction[taskId] = true;

        emit AuctionCreated(auctionId, taskId, block.timestamp + commitDuration, block.timestamp + duration);
    }

    /**
     * @notice Commit a sealed bid. Must include a non-zero ETH deposit.
     * @param auctionId Target auction.
     * @param commitment keccak256(abi.encode(msg.sender, amount, salt))
     */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp > auction.startTime + auction.commitDuration) revert AuctionNotActive();
        if (msg.value == 0) revert BidTooLow();

        SealedBid storage sb = sealedBids[auctionId][msg.sender];
        if (sb.commitment != bytes32(0)) revert AlreadyRevealed(); // already committed

        sb.commitment = keccak256(abi.encodePacked(msg.sender, msg.value, block.number));
        sb.deposit = msg.value;

        emit BidCommitted(auctionId, msg.sender, sb.commitment);
    }

    /**
     * @notice Commit overload allowing custom commitment hash.
     * @dev Preferred method: compute commitment off-chain.
     */
    function commitBid(uint256 auctionId, bytes32 commitment) external payable nonReentrant {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp > auction.startTime + auction.commitDuration) revert AuctionNotActive();
        if (msg.value == 0) revert BidTooLow();
        if (sealedBids[auctionId][msg.sender].commitment != bytes32(0)) revert AlreadyRevealed();

        sealedBids[auctionId][msg.sender] = SealedBid({
            commitment: commitment,
            deposit: msg.value,
            revealed: false
        });

        auctionBalances[auctionId] += msg.value;
        emit BidCommitted(auctionId, msg.sender, commitment);
    }

    /**
     * @notice Reveal phase. Bidders disclose amount and salt.
     */
    function revealBid(uint256 auctionId, uint256 amount, bytes32 salt) external nonReentrant {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp <= auction.startTime + auction.commitDuration) revert CommitPhaseActive();
        if (block.timestamp > auction.startTime + auction.commitDuration + auction.revealDuration) revert RevealPhaseEnded();

        SealedBid storage sb = sealedBids[auctionId][msg.sender];
        if (sb.commitment == bytes32(0)) revert InvalidCommitment();
        if (sb.revealed) revert AlreadyRevealed();

        bytes32 expected = keccak256(abi.encode(msg.sender, amount, salt));
        if (sb.commitment != expected) revert InvalidCommitment();

        sb.revealed = true;

        if (amount < auction.endPrice) {
            // bid below reserve → auto-reject, allow immediate refund
            sb.deposit = 0;
            (bool success, ) = payable(msg.sender).call{value: sb.deposit}("");
            if (!success) revert AuctionNotActive();
            return;
        }

        uint256 idx = auction.revealedCount;
        if (idx >= MAX_BIDS_PER_AUCTION) revert MaxBidsReached();
        revealedBids[auctionId][idx] = RevealedBid(msg.sender, amount, salt, true);
        auction.revealedCount = idx + 1;

        // Update Vickrey state
        if (amount > auction.highestBid) {
            auction.secondHighestBid = auction.highestBid == 0 ? auction.startPrice : auction.highestBid;
            auction.secondHighestBid = auction.secondHighestBid < auction.startPrice ? auction.startPrice : auction.secondHighestBid;
            auction.highestBid = amount;
            auction.highestBidder = msg.sender;
        } else if (amount > auction.secondHighestBid) {
            auction.secondHighestBid = amount;
        }

        emit BidRevealed(auctionId, msg.sender, amount);
    }

    /**
     * @notice Settle auction after reveal window closes.
     * Winner pays secondHighestBid (or startPrice if only one bidder).
     */
    function settleAuction(uint256 auctionId) external nonReentrant {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp <= auction.startTime + auction.commitDuration + auction.revealDuration) revert AuctionNotEnded();
        if (auction.settled) revert AlreadySettled();

        auction.settled = true;
        auction.phase = AuctionPhase.SETTLED;

        // If no valid bids, cancel
        if (auction.highestBidder == address(0)) {
            emit AuctionSettled(auctionId, address(0), 0);
            return;
        }

        uint256 winningPrice = auction.secondHighestBid < auction.startPrice ? auction.startPrice : auction.secondHighestBid;

        // Transfer winning price to protocol treasury (or task escrow)
        // Refund excess deposit to winner
        SealedBid storage winnerBid = sealedBids[auctionId][auction.highestBidder];
        uint256 excess = winnerBid.deposit - winningPrice;
        winnerBid.deposit = 0;
        auctionBalances[auctionId] -= winningPrice;

        if (excess > 0) {
            (bool refundOk, ) = payable(auction.highestBidder).call{value: excess}("");
            if (!refundOk) revert AuctionNotActive();
        }

        emit AuctionSettled(auctionId, auction.highestBidder, winningPrice);
    }

    function cancelAuction(uint256 auctionId) external {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (auction.settled) revert AlreadySettled();
        if (msg.sender != owner()) revert UnauthorizedCancellation();

        auction.settled = true;
        auction.phase = AuctionPhase.SETTLED;

        // Allow all bidders to claim refunds via claimRefund
        emit AuctionCancelled(auctionId);
    }

    /**
     * @notice Losing bidders (or cancelled auction participants) reclaim deposits.
     */
    function claimRefund(uint256 auctionId) external nonReentrant {
        AuctionData storage auction = auctions[auctionId];
        if (!auction.settled && block.timestamp <= auction.startTime + auction.commitDuration + auction.revealDuration) revert AuctionNotActive();

        SealedBid storage sb = sealedBids[auctionId][msg.sender];
        uint256 amount = sb.deposit;
        if (amount == 0) revert AuctionNotActive();

        // Winner only gets excess refund during settleAuction; here they get nothing
        if (msg.sender == auction.highestBidder && auction.highestBidder != address(0)) {
            // Already handled in settleAuction
            if (amount > 0) revert AuctionNotActive();
        }

        sb.deposit = 0;
        auctionBalances[auctionId] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert AuctionNotActive();

        emit RefundClaimed(auctionId, msg.sender, amount);
    }

    function getCurrentPrice(uint256 auctionId) external view override returns (uint256) {
        AuctionData storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        // In Vickrey, "current price" is best estimate: second highest bid so far (if reveal open) or final price
        if (auction.settled) {
            uint256 winningPrice = auction.secondHighestBid < auction.startPrice ? auction.startPrice : auction.secondHighestBid;
            return winningPrice;
        }
        return auction.startPrice;
    }

    function getAuction(uint256 auctionId) external view override returns (Auction memory legacy) {
        AuctionData storage a = auctions[auctionId];
        // Map to legacy struct for backward compatibility
        return Auction({
            taskId: a.taskId,
            startPrice: a.startPrice,
            endPrice: a.endPrice,
            startTime: a.startTime,
            duration: a.duration,
            highestBidder: a.highestBidder,
            highestBid: a.highestBid,
            settled: a.settled
        });
    }

    // Legacy struct from ITaskAuction
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

    event AuctionCancelled(uint256 indexed auctionId);

    receive() external payable {}
}
