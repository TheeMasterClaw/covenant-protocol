pragma circom 2.1.9;

include "circomlib/poseidon.circom";
include "circomlib/comparators.circom";
include "circomlib/mux1.circom";

/**
 * @title JuryEligibility
 * @notice Proves a juror is in the reputation Merkle tree with score >= threshold
 *         without revealing their identity or exact score.
 * @param n Merkle tree depth (e.g., 20 for 2^20 leaves)
 *
 * Public Inputs (6):
 *   [0] merkleRoot
 *   [1] nullifierHash
 *   [ [2] disputeId ]
 *   [3] verdict
 *   [4] voteCommitment
 *   [5] minReputationThreshold
 *
 * Private Inputs (n + 4):
 *   identitySecret, reputationScore, merklePath[n], merklePathIndices[n]
 */
template JuryEligibility(n) {
    signal input identitySecret;
    signal input reputationScore;
    signal input merklePath[n];
    signal input merklePathIndices[n];

    signal input merkleRoot;
    signal input nullifierHash;
    signal input disputeId;
    signal input verdict;
    signal input voteCommitment;
    signal input minReputationThreshold;

    // 1. Prove reputationScore >= minReputationThreshold
    component gte = GreaterEqThan(64);
    gte.in[0] <== reputationScore;
    gte.in[1] <== minReputationThreshold;
    gte.out === 1;

    // 2. Compute identityCommitment = Poseidon(identitySecret)
    component idHasher = Poseidon(1);
    idHasher.inputs[0] <== identitySecret;
    signal identityCommitment <== idHasher.out;

    // 3. Compute leaf = Poseidon(identityCommitment, reputationScore)
    component leafHasher = Poseidon(2);
    leafHasher.inputs[0] <== identityCommitment;
    leafHasher.inputs[1] <== reputationScore;
    signal leaf <== leafHasher.out;

    // 4. Verify Merkle proof
    component hashers[n];
    component muxes[n];
    signal currentHash[n + 1];
    currentHash[0] <== leaf;

    for (var i = 0; i < n; i++) {
        muxes[i] = MultiMux1(2);
        muxes[i].c[0][0] <== currentHash[i];
        muxes[i].c[0][1] <== merklePath[i];
        muxes[i].c[1][0] <== merklePath[i];
        muxes[i].c[1][1] <== currentHash[i];
        muxes[i].s <== merklePathIndices[i];

        hashers[i] = Poseidon(2);
        hashers[i].inputs[0] <== muxes[i].out[0];
        hashers[i].inputs[1] <== muxes[i].out[1];
        currentHash[i + 1] <== hashers[i].out;
    }
    merkleRoot === currentHash[n];

    // 5. Compute and constrain nullifierHash = Poseidon(identitySecret, disputeId)
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== identitySecret;
    nullifierHasher.inputs[1] <== disputeId;
    nullifierHash === nullifierHasher.out;

    // 6. Constrain voteCommitment = Poseidon(nullifierHash, verdict)
    component voteHasher = Poseidon(2);
    voteHasher.inputs[0] <== nullifierHash;
    voteHasher.inputs[1] <== verdict;
    voteCommitment === voteHasher.out;
}

component main {public [merkleRoot, nullifierHash, disputeId, verdict, voteCommitment, minReputationThreshold]} = JuryEligibility(20);
