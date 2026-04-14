// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "../interfaces/IReputationOracle.sol";

interface ITellor {
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        external view returns (bool _ifRetrieve, uint256 _value, uint256 _timestampRetrieved);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _data) external;
}

/**
 * @title CovenantTellorAdapter
 * @notice Adapter for Tellor permissionless oracle
 * @dev Best for: web scraping, community-verified data, long-tail queries
 */
contract CovenantTellorAdapter {
    IReputationOracle public reputationOracle;
    ITellor public tellor;

    mapping(bytes32 => uint256) public queryIdToTask;

    event ScrapeRequested(uint256 indexed taskId, bytes32 indexed queryId, uint256 tip);
    event ScrapeVerified(uint256 indexed taskId, bytes32 indexed queryId, uint8 confidence);

    constructor(address reputationOracleAddress, address tellorAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        tellor = ITellor(tellorAddress);
    }

    function requestScrapeVerification(uint256 taskId, bytes32 queryId, uint256 tip) external {
        queryIdToTask[queryId] = taskId;
        tellor.tipQuery(queryId, tip, "");
        emit ScrapeRequested(taskId, queryId, tip);
    }

    function verifyFromTellor(bytes32 queryId, bytes32 dataHash, uint256 timestamp) external {
        uint256 taskId = queryIdToTask[queryId];
        require(taskId != 0, "Unknown query");

        (bool retrieved, uint256 value, uint256 retrievedTime) = tellor.getDataBefore(queryId, timestamp);
        require(retrieved && retrievedTime > 0, "No data available");

        uint8 confidence = uint8(value > 100 ? 100 : value);

        reputationOracle.submitVerification(
            dataHash,
            confidence,
            abi.encodePacked(queryId, retrievedTime),
            IReputationOracle.OracleType.Tellor,
            taskId
        );

        emit ScrapeVerified(taskId, queryId, confidence);
    }
}
