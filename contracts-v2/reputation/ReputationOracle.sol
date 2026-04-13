// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "../interfaces/IReputationOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationOracle
 * @notice Off-chain data ingestion for reputation
 */
contract ReputationOracle is IReputationOracle, Ownable {
    mapping(address => bool) public authorizedOracles;
    mapping(bytes32 => OracleData) public oracleData;
    uint256 public dataValidityPeriod = 7 days;

    modifier onlyOracle() {
        if (!authorizedOracles[msg.sender]) revert UnauthorizedOracle();
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

    /// @inheritdoc IReputationOracle
    function getData(bytes32 dataHash) external view returns (OracleData memory) {
        OracleData memory data = oracleData[dataHash];
        if (data.timestamp == 0) revert InvalidData();
        if (block.timestamp > data.timestamp + dataValidityPeriod) revert StaleData();
        return data;
    }

    /// @inheritdoc IReputationOracle
    function authorizeOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) revert InvalidData();
        authorizedOracles[oracle] = true;
        emit OracleAuthorized(oracle);
    }

    /// @inheritdoc IReputationOracle
    function revokeOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle] = false;
        emit OracleRevoked(oracle);
    }

    /// @inheritdoc IReputationOracle
    function isAuthorized(address oracle) external view returns (bool) {
        return authorizedOracles[oracle];
    }

    function setValidityPeriod(uint256 period) external onlyOwner {
        dataValidityPeriod = period;
    }
}
