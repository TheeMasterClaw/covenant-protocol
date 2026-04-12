// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./utils/Pausable.sol";

/**
 * @title AgentCovenant
 * @notice Individual covenant agreement between two AI agents
 * @dev Stores terms, handles disputes, manages escrow
 * Includes ReentrancyGuard and Pausable for security
 */
contract AgentCovenant is ReentrancyGuard, Pausable {
    
    // ============ Enums ============
    
    enum CovenantStatus {
        PENDING,      // Waiting for counterparty acceptance
        ACTIVE,       // Covenant is active
        FULFILLED,    // Terms completed successfully
        DISPUTED,     // Under dispute
        RESOLVED,     // Dispute resolved
        EXPIRED,      // Past deadline
        BREACHED      // Terms violated
    }
    
    enum Party {
        INITIATOR,
        COUNTERPARTY
    }
    
    // ============ Structs ============
    
    struct CovenantTerms {
        bytes32 covenantType;      // TASK, ALLIANCE, ESCROW, etc.
        string termsIPFSHash;      // Detailed terms stored on IPFS
        uint256 createdAt;         // Creation timestamp
        uint256 expiresAt;         // Expiration timestamp
        uint256 stakeAmount;       // Amount staked by initiator
    }
    
    struct Milestone {
        string description;
        uint256 paymentAmount;
        bool completed;
        bool paid;
        uint256 completedAt;
    }
    
    // ============ State Variables ============
    
    address public immutable initiator;
    address public immutable counterparty;
    CovenantTerms public terms;
    CovenantStatus public status;
    
    Milestone[] public milestones;
    uint256 public totalMilestonePayments;
    uint256 public remainingBalance;
    
    address public feeRecipient;
    uint256 public protocolFeeBps;
    
    mapping(address => bool) public hasAccepted;
    mapping(address => bytes32) public agentCommitments; // Hashed commitments for milestones
    
    address public disputeResolver;
    string public disputeReason;
    uint256 public disputedAt;
    
    // ============ Events ============
    
    event CovenantAccepted(address indexed by);
    event CovenantActivated();
    event MilestoneAdded(uint256 indexed index, string description, uint256 payment);
    event MilestoneCompleted(uint256 indexed index, address indexed by);
    event MilestonePaid(uint256 indexed index, uint256 amount);
    event DisputeRaised(address indexed by, string reason);
    event DisputeResolved(address indexed resolver, uint256 initiatorAward, uint256 counterpartyAward);
    event CovenantFulfilled();
    event CovenantBreached(address indexed by, string reason);
    event FundsWithdrawn(address indexed by, uint256 amount);
    
    // ============ Modifiers ============
    
    modifier onlyParty() {
        require(
            msg.sender == initiator || msg.sender == counterparty,
            "Not a party"
        );
        _;
    }
    
    modifier onlyInitiator() {
        require(msg.sender == initiator, "Not initiator");
        _;
    }
    
    modifier onlyActive() {
        require(status == CovenantStatus.ACTIVE, "Not active");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _initiator,
        address _counterparty,
        bytes32 _covenantType,
        string memory _termsIPFSHash,
        uint256 _duration,
        uint256 _stakeAmount,
        address _feeRecipient,
        uint256 _protocolFeeBps
    ) payable {
        initiator = _initiator;
        counterparty = _counterparty;
        feeRecipient = _feeRecipient;
        protocolFeeBps = _protocolFeeBps;
        remainingBalance = msg.value;
        
        terms = CovenantTerms({
            covenantType: _covenantType,
            termsIPFSHash: _termsIPFSHash,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + _duration,
            stakeAmount: _stakeAmount
        });
        
        status = CovenantStatus.PENDING;
        hasAccepted[_initiator] = true; // Initiator auto-accepts
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Counterparty accepts the covenant
     */
    function acceptCovenant() external whenNotPaused nonReentrant {
        require(msg.sender == counterparty, "Not counterparty");
        require(status == CovenantStatus.PENDING, "Not pending");
        require(block.timestamp < terms.expiresAt, "Expired");
        
        hasAccepted[counterparty] = true;
        status = CovenantStatus.ACTIVE;
        
        emit CovenantAccepted(counterparty);
        emit CovenantActivated();
    }
    
    /**
     * @notice Add a milestone with payment
     */
    function addMilestone(
        string calldata _description,
        uint256 _paymentAmount
    ) external whenNotPaused nonReentrant onlyInitiator onlyActive {
        require(_paymentAmount <= remainingBalance, "Insufficient balance");
        
        milestones.push(Milestone({
            description: _description,
            paymentAmount: _paymentAmount,
            completed: false,
            paid: false,
            completedAt: 0
        }));
        
        totalMilestonePayments += _paymentAmount;
        
        emit MilestoneAdded(milestones.length - 1, _description, _paymentAmount);
    }
    
    /**
     * @notice Mark a milestone as completed
     */
    function completeMilestone(uint256 _milestoneIndex) external onlyActive {
        require(_milestoneIndex < milestones.length, "Invalid milestone");
        Milestone storage milestone = milestones[_milestoneIndex];
        require(!milestone.completed, "Already completed");
        
        milestone.completed = true;
        milestone.completedAt = block.timestamp;
        
        emit MilestoneCompleted(_milestoneIndex, msg.sender);
    }
    
    /**
     * @notice Pay out a completed milestone
     */
    function payMilestone(uint256 _milestoneIndex) external whenNotPaused nonReentrant onlyInitiator onlyActive {
        require(_milestoneIndex < milestones.length, "Invalid milestone");
        Milestone storage milestone = milestones[_milestoneIndex];
        require(milestone.completed, "Not completed");
        require(!milestone.paid, "Already paid");
        
        milestone.paid = true;
        remainingBalance -= milestone.paymentAmount;
        
        // Calculate protocol fee
        uint256 fee = (milestone.paymentAmount * protocolFeeBps) / 10000;
        uint256 payment = milestone.paymentAmount - fee;
        
        // Pay fee
        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Pay counterparty
        (bool paySuccess, ) = counterparty.call{value: payment}("");
        require(paySuccess, "Payment failed");
        
        emit MilestonePaid(_milestoneIndex, payment);
        
        // Check if all milestones paid
        if (_allMilestonesPaid()) {
            status = CovenantStatus.FULFILLED;
            emit CovenantFulfilled();
        }
    }
    
    /**
     * @notice Raise a dispute
     */
    function raiseDispute(string calldata _reason) external whenNotPaused nonReentrant onlyParty {
        require(
            status == CovenantStatus.ACTIVE || status == CovenantStatus.PENDING,
            "Cannot dispute"
        );
        
        status = CovenantStatus.DISPUTED;
        disputeReason = _reason;
        disputedAt = block.timestamp;
        
        emit DisputeRaised(msg.sender, _reason);
    }
    
    /**
     * @notice Resolve a dispute (called by factory/disputeDAO)
     */
    function resolveDispute(
        uint256 _initiatorAward,
        uint256 _counterpartyAward
    ) external {
        require(status == CovenantStatus.DISPUTED, "Not disputed");
        require(
            _initiatorAward + _counterpartyAward <= remainingBalance,
            "Awards exceed balance"
        );
        
        status = CovenantStatus.RESOLVED;
        disputeResolver = msg.sender;
        
        // Distribute awards
        if (_initiatorAward > 0) {
            remainingBalance -= _initiatorAward;
            (bool success, ) = initiator.call{value: _initiatorAward}("");
            require(success, "Initiator award failed");
        }
        
        if (_counterpartyAward > 0) {
            remainingBalance -= _counterpartyAward;
            (bool success, ) = counterparty.call{value: _counterpartyAward}("");
            require(success, "Counterparty award failed");
        }
        
        // Return remaining to initiator
        if (remainingBalance > 0) {
            uint256 refund = remainingBalance;
            remainingBalance = 0;
            (bool success, ) = initiator.call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit DisputeResolved(msg.sender, _initiatorAward, _counterpartyAward);
    }
    
    /**
     * @notice Declare covenant breached
     */
    function declareBreach(string calldata _reason) external onlyParty {
        require(status == CovenantStatus.ACTIVE, "Not active");
        require(block.timestamp > terms.expiresAt, "Not expired yet");
        
        status = CovenantStatus.BREACHED;
        
        // Return remaining funds to initiator
        if (remainingBalance > 0) {
            uint256 refund = remainingBalance;
            remainingBalance = 0;
            (bool success, ) = initiator.call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit CovenantBreached(msg.sender, _reason);
    }
    
    /**
     * @notice Withdraw remaining funds (initiator only, after expiry)
     */
    function withdrawRemaining() external onlyInitiator {
        require(
            status == CovenantStatus.EXPIRED || 
            status == CovenantStatus.BREACHED ||
            status == CovenantStatus.FULFILLED ||
            block.timestamp > terms.expiresAt,
            "Cannot withdraw yet"
        );
        
        require(remainingBalance > 0, "No balance");
        
        uint256 amount = remainingBalance;
        remainingBalance = 0;
        
        (bool success, ) = initiator.call{value: amount}("");
        require(success, "Withdraw failed");
        
        emit FundsWithdrawn(initiator, amount);
    }
    
    // ============ View Functions ============
    
    function getMilestoneCount() external view returns (uint256) {
        return milestones.length;
    }
    
    function getMilestone(uint256 _index) external view returns (Milestone memory) {
        require(_index < milestones.length, "Invalid index");
        return milestones[_index];
    }
    
    function isActive() external view returns (bool) {
        return status == CovenantStatus.ACTIVE;
    }
    
    function timeRemaining() external view returns (uint256) {
        if (block.timestamp >= terms.expiresAt) return 0;
        return terms.expiresAt - block.timestamp;
    }
    
    // ============ Internal Functions ============
    
    function _allMilestonesPaid() internal view returns (bool) {
        for (uint256 i = 0; i < milestones.length; i++) {
            if (!milestones[i].paid) return false;
        }
        return true;
    }
    
    // Allow receiving ETH
    receive() external payable {
        remainingBalance += msg.value;
    }
}
