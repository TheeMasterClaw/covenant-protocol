# Critical Security Patches for COVENANT Protocol

## CV-001: Reentrancy in TaskAuction.placeBid()

### Original (Vulnerable)
```solidity
function placeBid(uint256 auctionId) external payable nonReentrant {
    Auction storage auction = auctions[auctionId];
    if (auction.taskId == 0) revert AuctionNotFound();
    if (block.timestamp > auction.startTime + auction.duration) revert AuctionNotActive();
    if (auction.settled) revert AlreadySettled();

    uint256 currentPrice = getCurrentPrice(auctionId);
    if (msg.value < currentPrice) revert BidTooLow();
    if (msg.value <= auction.highestBid) revert BidTooLow();

    // VULNERABLE: External call BEFORE state update
    if (auction.highestBidder != address(0)) {
        (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
        if (!success) revert AuctionNotActive();
    }

    auction.highestBidder = msg.sender;
    auction.highestBid = msg.value;

    emit BidPlaced(auctionId, msg.sender, msg.value);
}
```

### Fixed (Pull Pattern)
```solidity
contract TaskAuction is ITaskAuction, Ownable, ReentrancyGuard {
    // Add pending refunds mapping
    mapping(address => uint256) public pendingRefunds;
    
    function placeBid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        if (auction.taskId == 0) revert AuctionNotFound();
        if (block.timestamp > auction.startTime + auction.duration) revert AuctionNotActive();
        if (auction.settled) revert AlreadySettled();

        uint256 currentPrice = getCurrentPrice(auctionId);
        if (msg.value < currentPrice) revert BidTooLow();
        if (msg.value <= auction.highestBid) revert BidTooLow();

        // Cache previous bidder
        address previousBidder = auction.highestBidder;
        uint256 previousBid = auction.highestBid;

        // UPDATE STATE FIRST
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(auctionId, msg.sender, msg.value);

        // Queue refund instead of sending directly
        if (previousBidder != address(0)) {
            pendingRefunds[previousBidder] += previousBid;
        }
    }
    
    function withdrawRefund() external nonReentrant {
        uint256 amount = pendingRefunds[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        
        pendingRefunds[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert RefundFailed();
    }
}
```

---

## CV-002: Flash Loan Governance Attack

### Original (Vulnerable)
```solidity
function castVote(uint256 proposalId, uint8 support) external {
    Proposal storage p = proposals[proposalId];
    if (block.timestamp < p.startTime) revert VotingNotStarted();
    if (block.timestamp > p.endTime) revert VotingEnded();
    if (hasVoted[proposalId][msg.sender]) revert InvalidProposal();
    if (support > 2) revert InvalidProposal();

    // VULNERABLE: Uses current balance
    uint256 votes = token.balanceOf(msg.sender);
    hasVoted[proposalId][msg.sender] = true;

    if (support == 0) p.againstVotes += votes;
    else if (support == 1) p.forVotes += votes;
    else p.abstainVotes += votes;

    emit VoteCast(proposalId, msg.sender, support, votes);
}
```

### Fixed (ERC20Votes with Snapshot)
```solidity
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// Update COVEN token
contract COVEN is ICOVEN, ERC20Votes, ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _inflationRate
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        inflationRate = _inflationRate;
        lastMintTime = block.timestamp;
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
}

// Update Governor
contract CovenantGovernor is ICovenantGovernor, Ownable, ReentrancyGuard {
    struct Proposal {
        // ... existing fields ...
        uint256 snapshotBlock;  // NEW: Block at voting power is determined
    }

    function propose(...) external returns (uint256 proposalId) {
        // ... validation ...
        
        uint256 snapshot = block.number - 1;
        
        proposals[proposalId] = Proposal({
            // ... other fields ...
            snapshotBlock: snapshot
        });
    }

    function castVote(uint256 proposalId, uint8 support) external {
        Proposal storage p = proposals[proposalId];
        // ... validation ...
        
        // FIXED: Use snapshot voting power
        uint256 votes = token.getPastVotes(msg.sender, p.snapshotBlock);
        if (votes == 0) revert NoVotingPower();
        
        hasVoted[proposalId][msg.sender] = true;
        
        // ... voting logic ...
    }
}
```

---

## CV-003: MultiSig Signer Removal Brick

### Original (Vulnerable)
```solidity
function removeSigner(address _signer) external onlySigner {
    if (!signers[_signer]) revert InvalidSignerCount();
    signers[_signer] = false;  // Only sets mapping
    emit SignerRemoved(_signer);
    // MISSING: Threshold check!
}
```

### Fixed
```solidity
function removeSigner(address _signer) external onlySigner {
    if (!signers[_signer]) revert InvalidSignerCount();
    
    // Count valid signers
    uint256 validSignerCount;
    for (uint256 i = 0; i < signerList.length; i++) {
        if (signers[signerList[i]]) validSignerCount++;
    }
    
    // Check threshold after removal
    if (validSignerCount - 1 < requiredConfirmations) {
        revert WouldLockContract();
    }
    
    signers[_signer] = false;
    
    // Remove from array
    for (uint256 i = 0; i < signerList.length; i++) {
        if (signerList[i] == _signer) {
            signerList[i] = signerList[signerList.length - 1];
            signerList.pop();
            break;
        }
    }
    
    emit SignerRemoved(_signer);
}
```

---

## CV-004: Cross-Chain Replay Attack

### Original (Vulnerable)
```solidity
function receiveMessage(uint16 sourceChain, bytes calldata payload) external {
    if (!isChainSupported[sourceChain]) revert InvalidChain();
    if (msg.sender != supportedChains[sourceChain]) revert UnauthorizedRelayer();
    
    uint256 messageId = uint256(keccak256(abi.encodePacked(sourceChain, payload, block.timestamp)));
    messageStatuses[messageId] = 1;
    
    emit MessageReceived(messageId, sourceChain, payload);
}
```

### Fixed
```solidity
contract CovenantBridge is ICovenantBridge, Ownable, ReentrancyGuard {
    mapping(uint16 => uint64) public outboundNonces;
    mapping(uint16 => mapping(uint64 => bool)) public processedNonces;
    mapping(bytes32 => bool) public processedMessages;
    
    function sendMessage(uint16 targetChain, bytes calldata payload) 
        external 
        payable 
        nonReentrant 
        returns (uint256 messageId) 
    {
        if (!isChainSupported[targetChain]) revert InvalidChain();
        if (payload.length == 0 || payload.length > 10000) revert MessageTooLarge();

        uint64 nonce = outboundNonces[targetChain]++;
        
        messageId = uint256(keccak256(abi.encode(
            block.chainid,
            targetChain,
            nonce,
            msg.sender,
            payload,
            block.timestamp
        )));
        
        messageStatuses[messageId] = 0;
        emit MessageSent(messageId, targetChain, payload, nonce);
    }

    function receiveMessage(
        uint16 sourceChain, 
        uint64 nonce,
        bytes calldata payload,
        bytes calldata proof
    ) external {
        if (!isChainSupported[sourceChain]) revert InvalidChain();
        if (msg.sender != supportedChains[sourceChain]) revert UnauthorizedRelayer();
        if (processedNonces[sourceChain][nonce]) revert MessageAlreadyProcessed();
        
        if (!verifyProof(sourceChain, nonce, payload, proof)) {
            revert InvalidProof();
        }
        
        processedNonces[sourceChain][nonce] = true;
        
        bytes32 messageHash = keccak256(abi.encode(
            sourceChain,
            block.chainid,
            nonce,
            payload
        ));
        processedMessages[messageHash] = true;

        emit MessageReceived(uint256(messageHash), sourceChain, payload, nonce);
    }
}
```

---

## HV-001: Precision Loss in Staking

### Original
```solidity
uint256 reward = rewardPerSecond * timeElapsed;
accRewardPerShare += (reward * 1e12) / totalStakedAmount;
// Later: (amount * acc) / 1e12
```

### Fixed
```solidity
uint256 constant PRECISION = 1e27;

function updatePool() public {
    if (block.timestamp <= lastUpdateTime) return;
    if (totalStakedAmount == 0) {
        lastUpdateTime = block.timestamp;
        return;
    }

    uint256 timeElapsed = block.timestamp - lastUpdateTime;
    if (block.timestamp > rewardEndTime && rewardEndTime > lastUpdateTime) {
        timeElapsed = rewardEndTime - lastUpdateTime;
    }

    uint256 reward = rewardPerSecond * timeElapsed;
    uint256 rewardPerShare = (reward * PRECISION) / totalStakedAmount;
    
    accRewardPerShare += rewardPerShare;
    lastUpdateTime = block.timestamp;
}

function _pendingRewards(address account) internal view returns (uint256) {
    Stake storage userStake = stakes[account];
    uint256 _accRewardPerShare = accRewardPerShare;

    if (block.timestamp > lastUpdateTime && totalStakedAmount != 0) {
        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (block.timestamp > rewardEndTime && rewardEndTime > lastUpdateTime) {
            timeElapsed = rewardEndTime - lastUpdateTime;
        }
        uint256 reward = rewardPerSecond * timeElapsed;
        _accRewardPerShare += (reward * PRECISION) / totalStakedAmount;
    }

    return ((userStake.amount * _accRewardPerShare) / PRECISION) - userStake.rewardDebt;
}
```

---

## HV-002: Emergency Pause

### Pattern to Add to All Critical Contracts
```solidity
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract TaskMarket is ITaskMarket, Ownable, ReentrancyGuard, Pausable {
    function createTask(...) external payable nonReentrant whenNotPaused { ... }
    function assignTask(uint256 taskId) external whenNotPaused { ... }
    function submitTask(uint256 taskId, bytes32 proofHash) external whenNotPaused { ... }
    function completeTask(uint256 taskId) external nonReentrant whenNotPaused { ... }
    function disputeTask(uint256 taskId) external whenNotPaused { ... }
    function cancelTask(uint256 taskId) external nonReentrant whenNotPaused { ... }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}
```
