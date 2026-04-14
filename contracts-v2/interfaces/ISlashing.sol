// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISlashing {
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
    
    event SlashProposed(uint256 indexed slashId, address indexed target, uint256 severity, uint256 amount, string reason);
    event SlashExecuted(uint256 indexed slashId, address indexed target, uint256 amount, uint256 victimAmount, uint256 treasuryAmount, uint256 burnAmount);
    event SlashAppealed(uint256 indexed slashId, address indexed appellant, uint256 bondAmount);
    event SlashReversed(uint256 indexed slashId, address indexed appellant, uint256 bondReturned);
    event UserBanned(address indexed user);
    event InsuranceClaimed(address indexed claimant, uint256 amount);
    
    error UnauthorizedInitiator();
    error InvalidSeverity();
    error AlreadyExecuted();
    error AppealWindowClosed();
    error AppealWindowOpen();
    error InsufficientBond();
    error SlashNotFound();
    error BannedUser();
    error InvalidDistribution();
    
    function proposeSlash(address target, address stakeToken, SlashCategory category, uint256 severity, string calldata reason, bytes32 evidenceHash, uint256 totalStake, address victim) external returns (uint256 slashId);
    function executeSlash(uint256 slashId, address stakeToken) external;
    function appealSlash(uint256 slashId) external payable;
    function resolveAppeal(uint256 slashId, bool uphold) external;
    function slashMissedVote(address target, address stakeToken, uint256 totalStake) external returns (uint256 slashId);
    function slashLateDelivery(address target, address stakeToken, uint256 totalStake, uint256 daysLate) external returns (uint256 slashId);
    function slashFraud(address target, address stakeToken, uint256 totalStake, bytes32 evidenceHash) external returns (uint256 slashId);
    function depositInsurance(address token, uint256 amount) external;
    function claimInsurance(address token, uint256 amount, address claimant) external;
    function getSlashRecord(uint256 slashId) external view returns (SlashRecord memory);
    function getUserSlashes(address user) external view returns (uint256[] memory);
    function getOffenderHistory(address user) external view returns (uint256 totalOffenses, uint256 lastOffenseTime, uint256 reputationScore, bool isBanned);
    function canAppeal(uint256 slashId) external view returns (bool);
    function calculateSlashAmount(uint256 totalStake, uint256 severity, address target) external view returns (uint256);
}
