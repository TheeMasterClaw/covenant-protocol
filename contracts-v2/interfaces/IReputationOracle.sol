// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationOracle
 * @notice Interface for the ReputationOracle contract
 */
interface IReputationOracle {
    struct OracleData {
        bytes32 dataHash;
        uint256 timestamp;
        uint8 confidence; // 0-100
        address source;
    }

    event DataSubmitted(bytes32 indexed dataHash, address indexed source, uint8 confidence);
    event OracleAuthorized(address indexed oracle);
    event OracleRevoked(address indexed oracle);

    error UnauthorizedOracle();
    error InvalidData();
    error StaleData();

    function submitData(bytes32 dataHash, uint8 confidence, bytes calldata proof) external;
    function getData(bytes32 dataHash) external view returns (OracleData memory);
    function authorizeOracle(address oracle) external;
    function revokeOracle(address oracle) external;
    function isAuthorized(address oracle) external view returns (bool);
}
