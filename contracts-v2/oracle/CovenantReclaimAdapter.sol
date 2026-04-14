// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationOracle} from "../interfaces/IReputationOracle.sol";

interface IReclaimVerifier {
    function verifyProof(bytes calldata proof, bytes32[] calldata expectedClaimHashes) external view returns (bool);
}

/**
 * @title CovenantReclaimAdapter
 * @notice Adapter for Reclaim Protocol TLS proofs
 * @dev Best for: private API verification, Twitter/X data, HTTPS scraping
 */
contract CovenantReclaimAdapter {
    IReputationOracle public reputationOracle;
    IReclaimVerifier public reclaimVerifier;

    event VerificationSubmitted(uint256 indexed taskId, bytes32 indexed dataHash, uint8 confidence);

    constructor(address reputationOracleAddress, address reclaimAddress) {
        reputationOracle = IReputationOracle(reputationOracleAddress);
        reclaimVerifier = IReclaimVerifier(reclaimAddress);
    }

    function verifyAndSubmit(
        uint256 taskId,
        bytes32 dataHash,
        bytes calldata proof,
        bytes32[] calldata expectedClaimHashes,
        uint8 confidence
    ) external {
        bool valid = reclaimVerifier.verifyProof(proof, expectedClaimHashes);
        require(valid, "Invalid Reclaim proof");

        reputationOracle.submitVerification(
            dataHash,
            confidence,
            proof,
            IReputationOracle.OracleType.ReclaimProtocol,
            taskId
        );

        emit VerificationSubmitted(taskId, dataHash, confidence);
    }
}