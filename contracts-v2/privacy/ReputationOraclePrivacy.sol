// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationOraclePrivacy
 * @notice Extended ReputationOracle with Reclaim, zkEmail, and Polygon ID support
 * @dev Multi-oracle data ingestion for privacy-preserving reputation verification
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
}

interface IDKIMRegistry {
    function isDKIMPublicKeyHashValid(string memory domainName, bytes32 publicKeyHash) external view returns (bool);
}

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
}

interface ICredentialValidator {
    function verify(
        uint256 id,
        uint256[80] memory pubSignals,
        uint256[8] memory proof,
        bytes memory queryData
    ) external view returns (bool);
}

contract ReputationOraclePrivacy is Ownable {
    enum OracleType {
        Unknown,
        ChainlinkFunctions,
        UMAOptimisticOracle,
        API3,
        PythNetwork,
        Tellor,
        ReclaimProtocol,
        ZKEmail,
        PolygonID
    }

    struct OracleInfo {
        bool authorized;
        OracleType oracleType;
        uint8 trustWeight;
    }

    struct OracleData {
        bytes32 dataHash;
        uint256 timestamp;
        uint8 confidence;
        address source;
    }

    struct VerificationPayload {
        bytes32 dataHash;
        uint8 confidence;
        bytes proof;
        OracleType oracleType;
        uint256 taskId;
    }

    struct CredentialRequirement {
        uint256 schemaHash;
        uint256 claimPathKey;
        uint256 operator;
        uint256[] value;
        uint8 confidence;
        string description;
    }

    // Core oracle state
    mapping(address => OracleInfo) public authorizedOracles;
    mapping(bytes32 => OracleData) public oracleData;
    mapping(bytes32 => VerificationPayload) public verificationPayloads;
    mapping(uint256 => bytes32[]) public taskVerifications;
    mapping(uint256 => mapping(OracleType => bool)) public taskVerifiedByType;

    // Reclaim state
    IReclaim public reclaimVerifier;
    mapping(string => uint256) public reclaimProviderMinimums;
    mapping(bytes32 => bool) public usedReclaimIdentifiers;

    // zkEmail state
    IDKIMRegistry public dkimRegistry;
    IZKEmailVerifier public emailVerifier;
    mapping(uint256 => string[]) public emailTemplates;
    mapping(string => bool) public trustedDomains;
    mapping(string => uint8) public domainConfidence;

    // Polygon ID state
    ICredentialValidator public credentialValidator;
    mapping(bytes32 => CredentialRequirement) public credentialRequirements;
    mapping(uint256 => bool) public trustedSchemas;

    // Config
    uint256 public dataValidityPeriod = 7 days;
    uint8 public minimumConfidence = 60;
    uint8 public multiOracleThreshold = 2;

    event DataSubmitted(bytes32 indexed dataHash, address indexed source, uint8 confidence);
    event OracleAuthorized(address indexed oracle);
    event OracleRevoked(address indexed oracle);
    event ReclaimVerificationUsed(bytes32 indexed identifier, string provider, uint256 taskId);
    event EmailVerified(bytes32 indexed publicKeyHash, string domain, uint256 templateId);
    event CredentialVerified(address indexed subject, bytes32 indexed requirementId);
    event RequirementRegistered(bytes32 indexed requirementId, uint256 schemaHash, string description);

    error UnauthorizedOracle();
    error InvalidData();
    error StaleData();
    error InvalidProof();
    error AlreadyUsedIdentifier();
    error InvalidDomain();
    error DomainMismatch();
    error InvalidDKIMPublicKeyHash();
    error InvalidTemplate();
    error UntrustedSchema();
    error RequirementNotFound();
    error SchemaMismatch();

    modifier onlyOracle() {
        if (!authorizedOracles[msg.sender].authorized) revert UnauthorizedOracle();
        _;
    }

    constructor(
        address _reclaimVerifier,
        address _dkimRegistry,
        address _emailVerifier,
        address _credentialValidator
    ) Ownable(msg.sender) {
        reclaimVerifier = IReclaim(_reclaimVerifier);
        dkimRegistry = IDKIMRegistry(_dkimRegistry);
        emailVerifier = IZKEmailVerifier(_emailVerifier);
        credentialValidator = ICredentialValidator(_credentialValidator);

        // Default provider minimums
        reclaimProviderMinimums["github-contributions"] = 10;
        reclaimProviderMinimums["upwork-rating"] = 450;
        reclaimProviderMinimums["stripe-payment"] = 1;

        // Default trusted domains
        trustedDomains["stripe.com"] = true;
        trustedDomains["github.com"] = true;
        trustedDomains["upwork.com"] = true;
        trustedDomains["gmail.com"] = true;

        domainConfidence["stripe.com"] = 90;
        domainConfidence["github.com"] = 85;
        domainConfidence["upwork.com"] = 80;
        domainConfidence["gmail.com"] = 70;
    }

    // ============ Standard Oracle Interface ============

    function submitData(bytes32 dataHash, uint8 confidence, bytes calldata proof) external onlyOracle {
        if (dataHash == bytes32(0)) revert InvalidData();
        if (confidence > 100) revert InvalidData();

        OracleType oType = authorizedOracles[msg.sender].oracleType;

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            source: msg.sender
        });

        emit DataSubmitted(dataHash, msg.sender, confidence);
    }

    function getData(bytes32 dataHash) external view returns (OracleData memory) {
        OracleData memory data = oracleData[dataHash];
        if (data.timestamp == 0) revert InvalidData();
        if (block.timestamp > data.timestamp + dataValidityPeriod) revert StaleData();
        return data;
    }

    // ============ Reclaim Protocol Integration ============

    function submitReclaimProof(
        IReclaim.Proof calldata proof,
        uint256 taskId
    ) external {
        bytes32 identifier = proof.signedClaim.identifier;
        if (usedReclaimIdentifiers[identifier]) revert AlreadyUsedIdentifier();

        bool valid = reclaimVerifier.verifyProof(proof);
        if (!valid) revert InvalidProof();

        usedReclaimIdentifiers[identifier] = true;

        bytes32 dataHash = keccak256(abi.encodePacked(
            proof.claimInfo.provider,
            proof.claimInfo.parameters,
            proof.claimInfo.context
        ));

        uint8 confidence = _computeReclaimConfidence(proof.claimInfo.provider);

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            source: address(reclaimVerifier)
        });

        bytes32 payloadId = keccak256(abi.encodePacked(dataHash, taskId, block.timestamp));
        verificationPayloads[payloadId] = VerificationPayload({
            dataHash: dataHash,
            confidence: confidence,
            proof: abi.encode(proof),
            oracleType: OracleType.ReclaimProtocol,
            taskId: taskId
        });

        taskVerifications[taskId].push(payloadId);
        taskVerifiedByType[taskId][OracleType.ReclaimProtocol] = true;

        emit DataSubmitted(dataHash, address(reclaimVerifier), confidence);
        emit ReclaimVerificationUsed(identifier, proof.claimInfo.provider, taskId);
    }

    function _computeReclaimConfidence(string memory provider) internal view returns (uint8) {
        if (keccak256(bytes(provider)) == keccak256(bytes("github-contributions"))) return 85;
        if (keccak256(bytes(provider)) == keccak256(bytes("upwork-rating"))) return 80;
        if (keccak256(bytes(provider)) == keccak256(bytes("stripe-payment"))) return 90;
        if (keccak256(bytes(provider)) == keccak256(bytes("binance-balance"))) return 75;
        return 50;
    }

    // ============ zkEmail Integration ============

    struct EmailAuthMsg {
        IZKEmailVerifier.EmailProof proof;
        uint256 templateId;
        uint256[] commandParams;
        uint256 skippedCommandPrefix;
    }

    function submitEmailAttestation(
        EmailAuthMsg calldata emailAuthMsg,
        uint256 taskId
    ) external {
        IZKEmailVerifier.EmailProof memory proof = emailAuthMsg.proof;

        if (!trustedDomains[proof.domainName]) revert InvalidDomain();

        bool dkimValid = dkimRegistry.isDKIMPublicKeyHashValid(proof.domainName, proof.publicKeyHash);
        if (!dkimValid) revert InvalidDKIMPublicKeyHash();

        bool proofValid = emailVerifier.verifyEmailProof(proof);
        if (!proofValid) revert InvalidProof();

        if (emailTemplates[emailAuthMsg.templateId].length == 0) revert InvalidTemplate();

        bytes32 dataHash = keccak256(abi.encodePacked(
            proof.domainName,
            proof.maskedCommand,
            emailAuthMsg.commandParams
        ));

        uint8 confidence = domainConfidence[proof.domainName];

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            source: address(emailVerifier)
        });

        bytes32 payloadId = keccak256(abi.encodePacked(dataHash, taskId, block.timestamp));
        verificationPayloads[payloadId] = VerificationPayload({
            dataHash: dataHash,
            confidence: confidence,
            proof: abi.encode(emailAuthMsg),
            oracleType: OracleType.ZKEmail,
            taskId: taskId
        });

        taskVerifications[taskId].push(payloadId);
        taskVerifiedByType[taskId][OracleType.ZKEmail] = true;

        emit DataSubmitted(dataHash, address(emailVerifier), confidence);
        emit EmailVerified(proof.publicKeyHash, proof.domainName, emailAuthMsg.templateId);
    }

    function registerEmailTemplate(uint256 templateId, string[] calldata template) external onlyOwner {
        emailTemplates[templateId] = template;
    }

    function setDomainTrust(string calldata domain, bool trusted, uint8 confidence) external onlyOwner {
        trustedDomains[domain] = trusted;
        domainConfidence[domain] = confidence;
    }

    // ============ Polygon ID Integration ============

    function registerCredentialRequirement(
        bytes32 requirementId,
        uint256 schemaHash,
        uint256 claimPathKey,
        uint256 operator,
        uint256[] calldata value,
        uint8 confidence,
        string calldata description
    ) external onlyOwner {
        if (!trustedSchemas[schemaHash]) revert UntrustedSchema();

        credentialRequirements[requirementId] = CredentialRequirement({
            schemaHash: schemaHash,
            claimPathKey: claimPathKey,
            operator: operator,
            value: value,
            confidence: confidence,
            description: description
        });

        emit RequirementRegistered(requirementId, schemaHash, description);
    }

    function submitCredentialProof(
        bytes32 requirementId,
        address subject,
        uint256[80] calldata pubSignals,
        uint256[8] calldata proof,
        uint256 taskId
    ) external {
        CredentialRequirement memory req = credentialRequirements[requirementId];
        if (req.schemaHash == 0) revert RequirementNotFound();

        if (pubSignals[68] != req.schemaHash) revert SchemaMismatch();

        bytes memory queryData = abi.encode(req.schemaHash, req.claimPathKey, req.operator, req.value);

        bool valid = credentialValidator.verify(uint256(uint160(subject)), pubSignals, proof, queryData);
        if (!valid) revert InvalidProof();

        bytes32 dataHash = keccak256(abi.encodePacked(requirementId, subject, pubSignals[68]));

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: req.confidence,
            source: address(credentialValidator)
        });

        bytes32 payloadId = keccak256(abi.encodePacked(dataHash, taskId, block.timestamp));
        verificationPayloads[payloadId] = VerificationPayload({
            dataHash: dataHash,
            confidence: req.confidence,
            proof: abi.encode(proof),
            oracleType: OracleType.PolygonID,
            taskId: taskId
        });

        taskVerifications[taskId].push(payloadId);
        taskVerifiedByType[taskId][OracleType.PolygonID] = true;

        emit DataSubmitted(dataHash, address(credentialValidator), req.confidence);
        emit CredentialVerified(subject, requirementId);
    }

    function setTrustedSchema(uint256 schemaHash, bool trusted) external onlyOwner {
        trustedSchemas[schemaHash] = trusted;
    }

    // ============ Aggregated Queries ============

    function getTaskVerificationStatus(uint256 taskId)
        external
        view
        returns (bool verified, OracleType[] memory oracleTypes, uint256 aggregatedConfidence)
    {
        bytes32[] memory payloads = taskVerifications[taskId];
        uint256 count = payloads.length;
        if (count == 0) return (false, new OracleType[](0), 0);

        uint8 typeCount;
        OracleType[] memory typesFound = new OracleType[](9);
        uint256 totalConfidence;
        uint256 totalWeight;
        bool[10] memory seen;

        for (uint256 i = 0; i < count; ) {
            VerificationPayload memory p = verificationPayloads[payloads[i]];

            uint256 weight = 50;
            if (p.oracleType == OracleType.ReclaimProtocol) weight = 50;
            else if (p.oracleType == OracleType.ZKEmail) weight = 60;
            else if (p.oracleType == OracleType.PolygonID) weight = 70;
            else {
                OracleInfo memory info = authorizedOracles[oracleData[p.dataHash].source];
                weight = info.trustWeight > 0 ? info.trustWeight : 50;
            }

            totalConfidence += uint256(p.confidence) * weight;
            totalWeight += weight;

            if (!seen[uint8(p.oracleType)]) {
                seen[uint8(p.oracleType)] = true;
                typesFound[typeCount] = p.oracleType;
                typeCount++;
            }

            unchecked { ++i; }
        }

        oracleTypes = new OracleType[](typeCount);
        for (uint8 i = 0; i < typeCount; ) {
            oracleTypes[i] = typesFound[i];
            unchecked { ++i; }
        }

        verified = typeCount >= multiOracleThreshold;
        aggregatedConfidence = totalWeight > 0 ? totalConfidence / totalWeight : 0;
    }

    // ============ Admin Functions ============

    function authorizeOracle(address oracle, OracleType oType, uint8 trustWeight) external onlyOwner {
        authorizedOracles[oracle] = OracleInfo({
            authorized: true,
            oracleType: oType,
            trustWeight: trustWeight
        });
        emit OracleAuthorized(oracle);
    }

    function revokeOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle].authorized = false;
        emit OracleRevoked(oracle);
    }

    function setValidityPeriod(uint256 period) external onlyOwner {
        dataValidityPeriod = period;
    }

    function setMultiOracleThreshold(uint8 threshold) external onlyOwner {
        multiOracleThreshold = threshold;
    }
}
