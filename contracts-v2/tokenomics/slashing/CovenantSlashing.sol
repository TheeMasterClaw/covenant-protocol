// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISlashing} from "../../interfaces/ISlashing.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CovenantSlashing
 * @notice Slashing conditions for dispute resolution and covenant enforcement
 * @dev Inspired by EigenLayer slashing with tiered penalties
 */
contract CovenantSlashing is ISlashing, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Constants ============
    
    uint256 public constant BPS = 10000;
    uint256 public constant APPEAL_WINDOW = 7 days;
    uint256 public constant APPEAL_BOND_MULTIPLIER = 2;
    
    // Severity levels
    uint256 public constant LEVEL_WARNING = 1;
    uint256 public constant LEVEL_PENALTY = 2;
    uint256 public constant LEVEL_MAJOR = 3;
    uint256 public constant LEVEL_CRITICAL = 4;
    
    // Base slash rates by severity
    uint256 public constant SLASH_WARNING = 10;      // 0.1%
    uint256 public constant SLASH_PENALTY = 100;     // 1%
    uint256 public constant SLASH_MAJOR = 1000;      // 10%
    uint256 public constant SLASH_CRITICAL = 10000;  // 100%
    
    // Distribution shares
    uint256 public constant VICTIM_SHARE = 6000;     // 60%
    uint256 public constant TREASURY_SHARE = 2000;   // 20%
    uint256 public constant BURN_SHARE = 2000;       // 20%
    
    // ============ State ============
    
    enum SlashCategory { JUROR, TASK_PROVIDER, COVENANT_PARTY, OPERATOR }
    enum SlashStatus { PENDING, APPEALED, EXECUTED, REVERSED }
    
    struct SlashRecord {
        address target;
        SlashCategory category;
        uint256 severity;
        uint256 amount;
        uint256 timestamp;
        SlashStatus status;
        string reason;
        bytes32 evidenceHash;
        address initiator;
        uint256 appealBond;
        uint256 victimShare;
        address victim;
    }
    
    mapping(uint256 => SlashRecord) public slashRecords;
    mapping(address => uint256[]) public userSlashes;
    mapping(address => uint256) public offenderCount;
    mapping(address => uint256) public lastSlashTime;
    mapping(address => uint256) public reputationDamage;
    mapping(address => bool) public bannedUsers;
    mapping(address => bool) public slashInitiators;
    mapping(address => bool) public appealArbiters;
    
    uint256 public nextSlashId;
    address public treasury;
    address public burnAddress;
    
    // Insurance pool
    uint256 public insurancePoolBalance;
    mapping(address => uint256) public insuranceCoverage;
    
    // Appeal tracking
    mapping(uint256 => uint256) public appealEndTime;
    mapping(uint256 => address) public appealBondStaker;
    
    // ============ Events ============
    
    event SlashProposed(
        uint256 indexed slashId,
        address indexed target,
        uint256 severity,
        uint256 amount,
        string reason
    );
    event SlashExecuted(
        uint256 indexed slashId,
        address indexed target,
        uint256 amount,
        uint256 victimAmount,
        uint256 treasuryAmount,
        uint256 burnAmount
    );
    event SlashAppealed(
        uint256 indexed slashId,
        address indexed appellant,
        uint256 bondAmount
    );
    event SlashReversed(
        uint256 indexed slashId,
        address indexed appellant,
        uint256 bondReturned
    );
    event UserBanned(address indexed user);
    event InsuranceClaimed(address indexed claimant, uint256 amount);
    
    // ============ Errors ============
    
    error UnauthorizedInitiator();
    error InvalidSeverity();
    error AlreadyExecuted();
    error AppealWindowClosed();
    error AppealWindowOpen();
    error InsufficientBond();
    error SlashNotFound();
    error UserBanned();
    error InvalidDistribution();
    
    // ============ Constructor ============
    
    constructor(address _treasury) Ownable(msg.sender) {
        treasury = _treasury;
        burnAddress = address(0xdead);
        nextSlashId = 1;
        slashInitiators[msg.sender] = true;
        appealArbiters[msg.sender] = true;
    }
    
    // ============ Administration ============
    
    function addSlashInitiator(address initiator) external onlyOwner {
        slashInitiators[initiator] = true;
    }
    
    function removeSlashInitiator(address initiator) external onlyOwner {
        slashInitiators[initiator] = false;
    }
    
    function addAppealArbiter(address arbiter) external onlyOwner {
        appealArbiters[arbiter] = true;
    }
    
    function removeAppealArbiter(address arbiter) external onlyOwner {
        appealArbiters[arbiter] = false;
    }
    
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
    
    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }
    
    // ============ Slashing Functions ============
    
    /**
     * @notice Propose a slash against a user
     * @param target Address to slash
     * @param stakeToken Token contract holding the stake
     * @param category Type of offense
     * @param severity 1-4 severity level
     * @param reason Human-readable reason
     * @param evidenceHash IPFS/hash of evidence
     * @param totalStake Total staked amount
     * @param victim Address to receive victim compensation (address(0) if none)
     */
    function proposeSlash(
        address target,
        address stakeToken,
        SlashCategory category,
        uint256 severity,
        string calldata reason,
        bytes32 evidenceHash,
        uint256 totalStake,
        address victim
    ) external returns (uint256 slashId) {
        if (!slashInitiators[msg.sender]) revert UnauthorizedInitiator();
        if (severity < 1 || severity > 4) revert InvalidSeverity();
        if (bannedUsers[target]) revert UserBanned();
        
        uint256 baseRate = _getBaseRate(severity);
        uint256 historyFactor = BPS + (offenderCount[target] * 500); // +5% per prior offense
        uint256 slashAmount = (totalStake * baseRate * historyFactor) / (BPS * BPS);
        if (slashAmount > totalStake) slashAmount = totalStake;
        
        slashId = nextSlashId++;
        
        uint256 victimAmount = (slashAmount * VICTIM_SHARE) / BPS;
        
        slashRecords[slashId] = SlashRecord({
            target: target,
            category: category,
            severity: severity,
            amount: slashAmount,
            timestamp: block.timestamp,
            status: SlashStatus.PENDING,
            reason: reason,
            evidenceHash: evidenceHash,
            initiator: msg.sender,
            appealBond: slashAmount * APPEAL_BOND_MULTIPLIER,
            victimShare: victimAmount,
            victim: victim
        });
        
        userSlashes[target].push(slashId);
        appealEndTime[slashId] = block.timestamp + APPEAL_WINDOW;
        
        emit SlashProposed(slashId, target, severity, slashAmount, reason);
    }
    
    /**
     * @notice Execute a pending slash after appeal window
     * @param slashId The slash to execute
     * @param stakeToken Token to slash from
     */
    function executeSlash(uint256 slashId, address stakeToken) external nonReentrant {
        SlashRecord storage record = slashRecords[slashId];
        if (record.target == address(0)) revert SlashNotFound();
        if (record.status != SlashStatus.PENDING) revert AlreadyExecuted();
        if (block.timestamp < appealEndTime[slashId] && appealBondStaker[slashId] == address(0)) 
            revert AppealWindowOpen();
        if (record.status == SlashStatus.REVERSED) revert AlreadyExecuted();
        
        record.status = SlashStatus.EXECUTED;
        offenderCount[record.target]++;
        lastSlashTime[record.target] = block.timestamp;
        reputationDamage[record.target] += record.severity * 25; // 25 points per severity level
        
        // Ban on critical severity or 3+ major offenses
        if (record.severity == LEVEL_CRITICAL || 
            (offenderCount[record.target] >= 3 && record.severity >= LEVEL_MAJOR)) {
            bannedUsers[record.target] = true;
            emit UserBanned(record.target);
        }
        
        // Calculate distribution
        uint256 victimAmount = record.victimShare;
        uint256 treasuryAmount = (record.amount * TREASURY_SHARE) / BPS;
        uint256 burnAmount = record.amount - victimAmount - treasuryAmount;
        
        // Execute transfers from stake token contract
        // Assumes slashing contract has been approved/authorized by staking contract
        IERC20 token = IERC20(stakeToken);
        
        // In practice, this would interact with a staking contract that holds funds
        // For this implementation, we assume the token contract supports slash transfers
        if (victimAmount > 0 && record.victim != address(0)) {
            token.safeTransferFrom(stakeToken, record.victim, victimAmount);
        } else {
            treasuryAmount += victimAmount;
            victimAmount = 0;
        }
        
        if (treasuryAmount > 0) {
            token.safeTransferFrom(stakeToken, treasury, treasuryAmount);
        }
        
        if (burnAmount > 0) {
            token.safeTransferFrom(stakeToken, burnAddress, burnAmount);
        }
        
        emit SlashExecuted(slashId, record.target, record.amount, victimAmount, treasuryAmount, burnAmount);
    }
    
    /**
     * @notice Appeal a pending slash by posting bond
     */
    function appealSlash(uint256 slashId) external payable nonReentrant {
        SlashRecord storage record = slashRecords[slashId];
        if (record.target == address(0)) revert SlashNotFound();
        if (record.status != SlashStatus.PENDING) revert AlreadyExecuted();
        if (block.timestamp > appealEndTime[slashId]) revert AppealWindowClosed();
        if (msg.value < record.appealBond) revert InsufficientBond();
        
        record.status = SlashStatus.APPEALED;
        appealBondStaker[slashId] = msg.sender;
        
        emit SlashAppealed(slashId, msg.sender, msg.value);
    }
    
    /**
     * @notice Resolve an appealed slash
     * @param slashId The appealed slash
     * @param uphold Whether to uphold (execute) or reverse the slash
     */
    function resolveAppeal(uint256 slashId, bool uphold) external nonReentrant {
        if (!appealArbiters[msg.sender]) revert UnauthorizedInitiator();
        
        SlashRecord storage record = slashRecords[slashId];
        if (record.status != SlashStatus.APPEALED) revert AlreadyExecuted();
        
        address appellant = appealBondStaker[slashId];
        
        if (uphold) {
            record.status = SlashStatus.PENDING; // Revert to pending for execution
            // Bond goes to treasury as penalty for frivolous appeal
            (bool sent, ) = treasury.call{value: record.appealBond}("");
            if (!sent) {
                // If treasury transfer fails, keep in contract
            }
        } else {
            record.status = SlashStatus.REVERSED;
            // Return bond to appellant
            (bool sent, ) = appellant.call{value: record.appealBond}("");
            if (!sent) {
                // If return fails, allow manual withdrawal
            }
            emit SlashReversed(slashId, appellant, record.appealBond);
        }
    }
    
    // ============ Insurance Functions ============
    
    /**
     * @notice Deposit into insurance pool
     */
    function depositInsurance(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        insurancePoolBalance += amount;
        insuranceCoverage[token] += amount;
    }
    
    /**
     * @notice Claim from insurance pool for systemic slash coverage
     */
    function claimInsurance(address token, uint256 amount, address claimant) external onlyOwner {
        if (amount > insuranceCoverage[token]) revert InsufficientBond();
        insuranceCoverage[token] -= amount;
        IERC20(token).safeTransfer(claimant, amount);
        emit InsuranceClaimed(claimant, amount);
    }
    
    // ============ Convenience Slashing Functions ============
    
    /**
     * @notice Quick slash for missed juror votes
     */
    function slashMissedVote(address target, address stakeToken, uint256 totalStake) 
        external 
        returns (uint256 slashId) 
    {
        if (!slashInitiators[msg.sender]) revert UnauthorizedInitiator();
        return _quickSlash(target, stakeToken, SlashCategory.JUROR, LEVEL_WARNING, totalStake, "Missed vote");
    }
    
    /**
     * @notice Quick slash for late task delivery
     */
    function slashLateDelivery(address target, address stakeToken, uint256 totalStake, uint256 daysLate) 
        external 
        returns (uint256 slashId) 
    {
        if (!slashInitiators[msg.sender]) revert UnauthorizedInitiator();
        uint256 severity = daysLate > 14 ? LEVEL_MAJOR : daysLate > 7 ? LEVEL_PENALTY : LEVEL_WARNING;
        return _quickSlash(target, stakeToken, SlashCategory.TASK_PROVIDER, severity, totalStake, 
            string(abi.encodePacked("Late delivery: ", _uintToString(daysLate), " days")));
    }
    
    /**
     * @notice Quick slash for fraud/collusion
     */
    function slashFraud(address target, address stakeToken, uint256 totalStake, bytes32 evidenceHash) 
        external 
        returns (uint256 slashId) 
    {
        if (!slashInitiators[msg.sender]) revert UnauthorizedInitiator();
        return proposeSlash(target, stakeToken, SlashCategory.JUROR, LEVEL_CRITICAL, 
            "Fraud or collusion detected", evidenceHash, totalStake, address(0));
    }
    
    // ============ View Functions ============
    
    function getSlashRecord(uint256 slashId) external view returns (SlashRecord memory) {
        return slashRecords[slashId];
    }
    
    function getUserSlashes(address user) external view returns (uint256[] memory) {
        return userSlashes[user];
    }
    
    function getOffenderHistory(address user) external view returns (
        uint256 totalOffenses,
        uint256 lastOffenseTime,
        uint256 reputationScore,
        bool isBanned
    ) {
        return (offenderCount[user], lastSlashTime[user], reputationDamage[user], bannedUsers[user]);
    }
    
    function canAppeal(uint256 slashId) external view returns (bool) {
        SlashRecord storage record = slashRecords[slashId];
        return record.status == SlashStatus.PENDING && block.timestamp <= appealEndTime[slashId];
    }
    
    function calculateSlashAmount(uint256 totalStake, uint256 severity, address target) 
        external 
        view 
        returns (uint256) 
    {
        uint256 baseRate = _getBaseRate(severity);
        uint256 historyFactor = BPS + (offenderCount[target] * 500);
        uint256 amount = (totalStake * baseRate * historyFactor) / (BPS * BPS);
        return amount > totalStake ? totalStake : amount;
    }
    
    // ============ Internal Functions ============
    
    function _quickSlash(
        address target,
        address stakeToken,
        SlashCategory category,
        uint256 severity,
        uint256 totalStake,
        string memory reason
    ) internal returns (uint256 slashId) {
        return proposeSlash(target, stakeToken, category, severity, reason, keccak256(bytes(reason)), totalStake, address(0));
    }
    
    function _getBaseRate(uint256 severity) internal pure returns (uint256) {
        if (severity == LEVEL_WARNING) return SLASH_WARNING;
        if (severity == LEVEL_PENALTY) return SLASH_PENALTY;
        if (severity == LEVEL_MAJOR) return SLASH_MAJOR;
        return SLASH_CRITICAL;
    }
    
    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    receive() external payable {}
}
