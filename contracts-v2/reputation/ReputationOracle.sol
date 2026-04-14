// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "../interfaces/IReputationOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationOracle
 * @notice Multi-oracle data ingestion for AI agent reputation with support for:
 *         - Chainlink Functions
 *         - UMA Optimistic Oracle
 *         - API3
 *         - Pyth Network
 *         - Tellor
 *         - Reclaim Protocol (TLS proofs)
 */
contract ReputationOracle is IReputationOracle, Ownable {

    struct OracleInfo {
        bool authorized;
        OracleType oracleType;
        uint8 trustWeight; // 0-100, used in multi-source aggregation
    }

    mapping(address => OracleInfo) public authorizedOracles;
    mapping(bytes32 => OracleData) public oracleData;
    mapping(bytes32 => VerificationPayload) public verificationPayloads;
    mapping(uint256 => bytes32[]) public taskVerifications;
    mapping(uint256 => mapping(OracleType => bool)) public taskVerifiedByType;

    uint256 public dataValidityPeriod = 7 days;
    uint8 public minimumConfidence = 60;
    uint8 public multiOracleThreshold = 2; // Number of distinct oracle types required for high-stakes tasks

    modifier onlyOracle() {
        if (!authorizedOracles[msg.sender].authorized) revert UnauthorizedOracle();
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IReputationOracle
    function submitData(bytes32 dataHash, uint8 confidence, bytes calldata proof) external onlyOracle {
        if (dataHash == bytes32(0)) revert InvalidData();
        if (confidence > 100) revert InvalidData();

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            source: msg.sender
        });

        emit DataSubmitted(dataHash, msg.sender, confidence);
    }

    /**
     * @notice Submit verification data with oracle type and task association
     * @param dataHash Hash of the verified data
     * @param confidence Confidence score 0-100
     * @param proof Oracle-specific proof bytes
     * @param oracleType Type of oracle providing verification
     * @param taskId Associated task ID
     */
    function submitVerification(
        bytes32 dataHash,
        uint8 confidence,
        bytes calldata proof,
        OracleType oracleType,
        uint256 taskId
    ) external onlyOracle {
        if (dataHash == bytes32(0)) revert InvalidData();
        if (confidence > 100) revert InvalidData();
        if (oracleType == OracleType.Unknown) revert InvalidData();

        OracleInfo memory info = authorizedOracles[msg.sender];
        if (info.oracleType != oracleType) revert InvalidData();

        oracleData[dataHash] = OracleData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            source: msg.sender
        });

        bytes32 payloadId = keccak256(abi.encodePacked(dataHash, taskId, block.timestamp));
        verificationPayloads[payloadId] = VerificationPayload({
            dataHash: dataHash,
            confidence: confidence,
            proof: proof,
            oracleType: oracleType,
            taskId: taskId
        });

        taskVerifications[taskId].push(payloadId);
        taskVerifiedByType[taskId][oracleType] = true;

        emit DataSubmitted(dataHash, msg.sender, confidence);
    }

    /**
     * @notice Check if a task has multi-oracle verification (enhanced security)
     * @param taskId Task to check
     * @return verified True if task has sufficient oracle diversity
     * @return oracleTypes Array of oracle types that verified
     * @return aggregatedConfidence Weighted average confidence
     */
    function getTaskVerificationStatus(uint256 taskId)
        external
        view
        returns (bool verified, OracleType[] memory oracleTypes, uint256 aggregatedConfidence)
    {
        bytes32[] memory payloads = taskVerifications[taskId];
        uint256 count = payloads.length;
        if (count == 0) return (false, new OracleType[](0), 0);

        uint8 typeCount;
        OracleType[] memory typesFound = new OracleType[](7);
        uint256 totalConfidence;
        uint256 totalWeight;

        // Track seen types
        bool[8] memory seen;

        for (uint256 i = 0; i < count; ) {
            VerificationPayload memory p = verificationPayloads[payloads[i]];
            OracleInfo memory info = authorizedOracles[oracleData[p.dataHash].source];

            totalConfidence += uint256(p.confidence) * uint256(info.trustWeight);
            totalWeight += info.trustWeight;

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

    /// @inheritdoc IReputationOracle
    function getData(bytes32 dataHash) external view returns (OracleData memory) {
        OracleData memory data = oracleData[dataHash];
        if (data.timestamp == 0) revert InvalidData();
        if (block.timestamp > data.timestamp + dataValidityPeriod) revert StaleData();
        return data;
    }

    /**
     * @notice Get verification payload by ID
     */
    function getVerificationPayload(bytes32 payloadId) external view returns (VerificationPayload memory) {
        return verificationPayloads[payloadId];
    }

    /**
     * @notice Get all verification payloads for a task
     */
    function getTaskVerifications(uint256 taskId) external view returns (bytes32[] memory) {
        return taskVerifications[taskId];
    }

    /// @inheritdoc IReputationOracle
    function authorizeOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) revert InvalidData();
        authorizedOracles[oracle].authorized = true;
        emit OracleAuthorized(oracle);
    }

    /**
     * @notice Authorize an oracle with specific type and trust weight
     */
    function authorizeOracleWithConfig(
        address oracle,
        OracleType oracleType,
        uint8 trustWeight
    ) external onlyOwner {
        if (oracle == address(0)) revert InvalidData();
        if (trustWeight > 100) revert InvalidData();
        authorizedOracles[oracle] = OracleInfo({
            authorized: true,
            oracleType: oracleType,
            trustWeight: trustWeight
        });
        emit OracleAuthorized(oracle);
    }

    /// @inheritdoc IReputationOracle
    function revokeOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle].authorized = false;
        emit OracleRevoked(oracle);
    }

    /// @inheritdoc IReputationOracle
    function isAuthorized(address oracle) external view returns (bool) {
        return authorizedOracles[oracle].authorized;
    }

    function setValidityPeriod(uint256 period) external onlyOwner {
        dataValidityPeriod = period;
    }

    function setMinimumConfidence(uint8 confidence) external onlyOwner {
        minimumConfidence = confidence;
    }

    function setMultiOracleThreshold(uint8 threshold) external onlyOwner {
        multiOracleThreshold = threshold;
    }
}