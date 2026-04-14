// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IReputationAdapter {
    function getScore(bytes32 agentHash) external view returns (uint256);
}

/**
 * @title ReputationAggregator
 * @notice Aggregates reputation scores from multiple AI agent frameworks
 */
contract ReputationAggregator is Ownable {
    constructor() Ownable(msg.sender) {}

    struct Source {
        address adapter;
        uint256 weight; // basis points, max 10000
        bool active;
    }

    Source[] public sources;
    mapping(bytes32 => uint256) public aggregatedReputation;
    mapping(bytes32 => uint256) public lastUpdated;

    uint256 public constant MAX_WEIGHT = 10000;
    uint256 public constant UPDATE_COOLDOWN = 1 hours;

    event SourceAdded(address indexed adapter, uint256 weight);
    event SourceUpdated(uint256 indexed index, uint256 weight, bool active);
    event ReputationComputed(bytes32 indexed agentHash, uint256 score);

    error InvalidWeight();
    error CooldownActive();
    error AdapterCallFailed();

    function addSource(address adapter, uint256 weight) external onlyOwner {
        if (weight == 0 || weight > MAX_WEIGHT) revert InvalidWeight();
        sources.push(Source(adapter, weight, true));
        emit SourceAdded(adapter, weight);
    }

    function updateSource(uint256 index, uint256 weight, bool active) external onlyOwner {
        if (weight == 0 || weight > MAX_WEIGHT) revert InvalidWeight();
        sources[index].weight = weight;
        sources[index].active = active;
        emit SourceUpdated(index, weight, active);
    }

    function computeReputation(bytes32 agentHash) external returns (uint256) {
        if (block.timestamp < lastUpdated[agentHash] + UPDATE_COOLDOWN) revert CooldownActive();

        uint256 totalWeight = 0;
        uint256 weightedScore = 0;

        for (uint i = 0; i < sources.length; i++) {
            Source memory src = sources[i];
            if (!src.active) continue;

            (bool success, bytes memory result) = src.adapter.staticcall(
                abi.encodeWithSelector(IReputationAdapter.getScore.selector, agentHash)
            );

            if (success && result.length >= 32) {
                uint256 score = abi.decode(result, (uint256));
                weightedScore += score * src.weight;
                totalWeight += src.weight;
            }
        }

        uint256 finalScore = totalWeight > 0 ? weightedScore / totalWeight : 0;
        aggregatedReputation[agentHash] = finalScore;
        lastUpdated[agentHash] = block.timestamp;

        emit ReputationComputed(agentHash, finalScore);
        return finalScore;
    }

    function getReputation(bytes32 agentHash) external view returns (uint256) {
        return aggregatedReputation[agentHash];
    }

    function sourceCount() external view returns (uint256) {
        return sources.length;
    }
}
