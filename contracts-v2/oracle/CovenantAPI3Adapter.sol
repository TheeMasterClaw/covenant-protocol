// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "../interfaces/IReputationOracle.sol";

interface IAPI3Proxy {
    function read() external view returns (int224 value, uint32 timestamp);
}

/**
 * @title CovenantAPI3Adapter
 * @notice Adapter for API3 first-party oracles
 * @dev Best for: financial data verification, enterprise API validation
 */
contract CovenantAPI3Adapter {
    IReputationOracle public reputationOracle;

    event FinancialDataVerified(uint256 indexed taskId, bytes32 indexed dataHash, int224 value, uint8 confidence);

    constructor(address reputationOracleAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
    }

    function verifyFinancialData(
        uint256 taskId,
        bytes32 dataHash,
        address dapiProxy,
        int224 expectedMin,
        int224 expectedMax
    ) external {
        (int224 value, uint32 timestamp) = IAPI3Proxy(dapiProxy).read();
        require(value >= expectedMin && value <= expectedMax, "Value out of range");
        require(block.timestamp - timestamp < 1 hours, "Stale data");

        reputationOracle.submitVerification(
            dataHash,
            95,
            abi.encodePacked(value, timestamp),
            IReputationOracle.OracleType.API3,
            taskId
        );

        emit FinancialDataVerified(taskId, dataHash, value, 95);
    }
}