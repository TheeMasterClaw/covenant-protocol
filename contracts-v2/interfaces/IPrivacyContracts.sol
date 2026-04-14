// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISemaphore
 * @notice Interface for Semaphore v4 protocol
 */
interface ISemaphore {
    struct SemaphoreProof {
        uint256 merkleTreeDepth;
        uint256 merkleTreeRoot;
        uint256 nullifier;
        uint256 message;
        uint256 scope;
        uint256[8] points;
    }
    
    function validateProof(uint256 groupId, SemaphoreProof calldata proof) external;
    function verifyProof(uint256 groupId, SemaphoreProof calldata proof) external view returns (bool);
    function groupCounter() external view returns (uint256);
    function createGroup(address admin, uint256 merkleTreeDuration) external returns (uint256);
    function addMember(uint256 groupId, uint256 identityCommitment) external;
    function removeMember(uint256 groupId, uint256 identityCommitment, uint256[] calldata merkleProofSiblings) external;
}

/**
 * @title IReclaim
 * @notice Interface for Reclaim Protocol TLS attestation
 */
interface IReclaim {
    struct ClaimInfo {
        string provider;
        string parameters;
        string context;
    }
    
    struct SignedClaim {
        bytes32 identifier;
        bytes32[] signatures;
    }
    
    struct Proof {
        ClaimInfo claimInfo;
        SignedClaim signedClaim;
    }
    
    function verifyProof(Proof memory proof) external view returns (bool);
    function fetchEpoch(uint32 epoch) external view returns (Epoch memory);
    
    struct Epoch {
        uint32 id;
        uint32 timestampStart;
        uint32 timestampEnd;
        Witness[] witnesses;
        uint8 minimumWitnessesForClaimCreation;
    }
    
    struct Witness {
        address addr;
        string host;
    }
}

/**
 * @title IDKIMRegistry
 * @notice Interface for zkEmail DKIM key registry
 */
interface IDKIMRegistry {
    function isDKIMPublicKeyHashValid(string memory domainName, bytes32 publicKeyHash) external view returns (bool);
    function setDKIMPublicKeyHash(string memory domainName, bytes32 publicKeyHash) external;
    function revokeDKIMPublicKeyHash(string memory domainName, bytes32 publicKeyHash) external;
}

/**
 * @title IZKEmailVerifier
 * @notice Interface for zkEmail proof verification
 */
interface IZKEmailVerifier {
    struct EmailProof {
        string domainName;
        bytes32 publicKeyHash;
        bytes32 timestamp;
        string maskedCommand;
        bytes32 accountSalt;
        bool isCodeExist;
        uint256[8] proof;
    }
    
    function verifyEmailProof(EmailProof memory proof) external view returns (bool);
    function commandBytes() external view returns (uint256);
    function loadVerificationKey() external pure returns (VerificationKey memory);
    
    struct VerificationKey {
        uint256[2] alfa1;
        uint256[2][2] beta2;
        uint256[2][2] gamma2;
        uint256[2][2] delta2;
        uint256[2][] IC;
    }
}

/**
 * @title ICredentialValidator
 * @notice Interface for Polygon ID / Iden3 credential verification
 */
interface ICredentialValidator {
    function verify(
        uint256 id,
        uint256[80] memory pubSignals,
        uint256[8] memory proof,
        bytes memory queryData
    ) external view returns (bool);
}

/**
 * @title IAnonymousJuryPool
 * @notice Interface for COVENANT anonymous jury pool
 */
interface IAnonymousJuryPool {
    enum Verdict { UNDECIDED, PLAINTIFF, DEFENDANT, SETTLEMENT }
    
    struct AnonymousVote {
        bytes32 nullifierHash;
        bytes32 voteCommitment;
        Verdict verdict;
        uint256 timestamp;
    }
    
    struct JurySession {
        uint256 disputeId;
        uint256 semaphoreGroupId;
        uint256 minReputationThreshold;
        bool resolved;
        Verdict finalVerdict;
        uint256 resolutionTime;
        uint256 voteCount;
    }
    
    function createSession(uint256 disputeId, uint256 minReputationThreshold, bytes32 credentialRequirementId) external returns (uint256 groupId);
    function submitAnonymousVote(uint256 disputeId, ISemaphore.SemaphoreProof calldata proof, Verdict verdict, bytes32 voteCommitment) external payable;
    function resolveDispute(uint256 disputeId) external returns (Verdict finalVerdict);
    function getVotes(uint256 disputeId) external view returns (AnonymousVote[] memory);
    function getSession(uint256 disputeId) external view returns (JurySession memory);
}

/**
 * @title IPrivateTaskMarket
 * @notice Interface for COVENANT private task market
 */
interface IPrivateTaskMarket {
    enum TaskStatus { OPEN, COMMIT, REVEAL, ASSIGNED, IN_PROGRESS, SUBMITTED, COMPLETED, DISPUTED, FINISHED, CANCELLED }
    
    struct Task {
        uint256 id;
        address poster;
        uint128 reward;
        address rewardToken;
        uint128 collateral;
        uint40 deadline;
        uint40 commitDeadline;
        uint40 revealDeadline;
        TaskStatus status;
        address assignee;
        uint64 minReputation;
        bool zkRequired;
        bytes32 metadataHash;
        bytes32 resultHash;
    }
    
    struct BidCommitment {
        bytes32 commitment;
        uint40 timestamp;
        bool revealed;
    }
    
    struct RevealedBid {
        address bidder;
        uint128 amount;
        uint40 estimatedTime;
        bytes32 proposalHash;
        uint64 reputation;
        bool accepted;
    }
    
    function postTask(uint128 reward, address rewardToken, uint40 totalDuration, uint64 minReputation, bool zkRequired, bytes32 metadataHash) external payable returns (uint256 taskId);
    function commitBid(uint256 taskId, bytes32 commitment, IZKBidValidator.BidProof calldata zkProof) external payable;
    function revealBid(uint256 taskId, uint128 amount, uint40 estimatedTime, bytes32 proposalHash, bytes32 salt) external;
    function acceptBid(uint256 taskId, uint256 bidIndex) external;
    function completeTask(uint256 taskId) external;
    function getTask(uint256 taskId) external view returns (Task memory);
    function getBids(uint256 taskId) external view returns (RevealedBid[] memory);
}

/**
 * @title IZKBidValidator
 * @notice Interface for ZK bid validity validator
 */
interface IZKBidValidator {
    struct BidProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[4] publicSignals;
    }
    
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[4] calldata publicSignals
    ) external view returns (bool);
}

/**
 * @title IReputationOraclePrivacy
 * @notice Interface for extended reputation oracle with privacy features
 */
interface IReputationOraclePrivacy {
    enum OracleType { Unknown, ChainlinkFunctions, UMAOptimisticOracle, API3, PythNetwork, Tellor, ReclaimProtocol, ZKEmail, PolygonID }
    
    struct OracleData {
        bytes32 dataHash;
        uint256 timestamp;
        uint8 confidence;
        address source;
    }
    
    function submitReclaimProof(IReclaim.Proof calldata proof, uint256 taskId) external;
    function submitEmailAttestation(IZKEmailReputationExtension.EmailAuthMsg calldata emailAuthMsg, uint256 taskId) external;
    function submitCredentialProof(bytes32 requirementId, address subject, uint256[80] calldata pubSignals, uint256[8] calldata proof, uint256 taskId) external;
    function getTaskVerificationStatus(uint256 taskId) external view returns (bool verified, OracleType[] memory oracleTypes, uint256 aggregatedConfidence);
}

/**
 * @title IZKEmailReputationExtension
 * @notice Interface for zkEmail reputation adapter
 */
interface IZKEmailReputationExtension {
    struct EmailAuthMsg {
        IZKEmailVerifier.EmailProof proof;
        uint256 templateId;
        uint256[] commandParams;
        uint256 skippedCommandPrefix;
    }
    
    function verifyEmailAttestation(EmailAuthMsg calldata emailAuthMsg, string calldata expectedDomain) external view returns (bytes32 dataHash, uint8 confidence);
    function setDomainTrust(string calldata domain, bool trusted, uint8 confidence) external;
}

/**
 * @title IPolygonIDReputationAdapter
 * @notice Interface for Polygon ID credential verification
 */
interface IPolygonIDReputationAdapter {
    struct CredentialRequirement {
        uint256 schemaHash;
        uint256 claimPathKey;
        uint256 operator;
        uint256[] value;
        uint8 confidence;
        string description;
    }
    
    function registerRequirement(bytes32 requirementId, uint256 schemaHash, uint256 claimPathKey, uint256 operator, uint256[] calldata value, uint8 confidence, string calldata description) external;
    function verifyCredential(bytes32 requirementId, address subject, uint256[80] calldata pubSignals, uint256[8] calldata proof) external view returns (bool verified, uint8 confidence);
    function setTrustedSchema(uint256 schemaHash, bool trusted) external;
}
