// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationOracle
 * @notice Interface for the ReputationOracle contract with multi-oracle support
 */
interface IReputationOracle {
    enum OracleType {
        Unknown,
        ChainlinkFunctions,
        UMAOptimisticOracle,
        API3,
        PythNetwork,
        Tellor,
        ReclaimProtocol
    }

    struct OracleData {
        bytes32 dataHash;
        uint256 timestamp;
        uint8 confidence; // 0-100
        address source;
    }

    struct VerificationPayload {
        bytes32 dataHash;
        uint8 confidence;
        bytes proof;
        OracleType oracleType;
        uint256 taskId;
    }

    event DataSubmitted(bytes32 indexed dataHash, address indexed source, uint8 confidence);
    event OracleAuthorized(address indexed oracle);
    event OracleRevoked(address indexed oracle);

    error UnauthorizedOracle();
    error InvalidData();
    error StaleData();

    function submitData(bytes32 dataHash, uint8 confidence, bytes calldata proof) external;
    function submitVerification(bytes32 dataHash, uint8 confidence, bytes calldata proof, OracleType oracleType, uint256 taskId) external;
    function getData(bytes32 dataHash) external view returns (OracleData memory);
    function getTaskVerificationStatus(uint256 taskId) external view returns (bool verified, OracleType[] memory oracleTypes, uint256 aggregatedConfidence);
    function authorizeOracle(address oracle) external;
    function authorizeOracleWithConfig(address oracle, OracleType oracleType, uint8 trustWeight) external;
    function revokeOracle(address oracle) external;
    function isAuthorized(address oracle) external view returns (bool);
}
