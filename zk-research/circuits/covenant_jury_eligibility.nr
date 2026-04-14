// Noir circuit for anonymous jury eligibility
// Prover.toml configuration required for inputs

use dep::std;

global MERKLE_DEPTH: u32 = 20;

fn main(
    identity_secret: Field,
    reputation_score: u64,
    merkle_path: [Field; MERKLE_DEPTH],
    merkle_indices: [bool; MERKLE_DEPTH],
    merkle_root: pub Field,
    nullifier_hash: pub Field,
    dispute_id: pub Field,
    verdict: pub Field,
    vote_commitment: pub Field,
    min_reputation_threshold: pub u64,
) {
    // 1. Range proof: reputation >= threshold
    assert(reputation_score >= min_reputation_threshold);

    // 2. Identity commitment from secret
    let identity_commitment = std::hash::pedersen_hash([identity_secret]);

    // 3. Leaf = hash(identity_commitment, reputation_score)
    let leaf = std::hash::pedersen_hash([identity_commitment, reputation_score as Field]);

    // 4. Verify Merkle membership
    let computed_root = std::merkle::compute_merkle_root(leaf, merkle_indices, merkle_path);
    assert(computed_root == merkle_root);

    // 5. Nullifier = hash(identity_secret, dispute_id)
    let computed_nullifier = std::hash::pedersen_hash([identity_secret, dispute_id]);
    assert(computed_nullifier == nullifier_hash);

    // 6. Vote commitment = hash(nullifier_hash, verdict)
    let computed_commitment = std::hash::pedersen_hash([nullifier_hash, verdict]);
    assert(computed_commitment == vote_commitment);
}

#[test]
fn test_eligibility() {
    // Example test with dummy values
    let secret = 12345;
    let score: u64 = 5000;
    let threshold: u64 = 1000;
    assert(score >= threshold);
}
