// SP1 Program: High-frequency reputation verification
// Located in: sp1/program/src/main.rs

#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_primitives::{Address, FixedBytes};
use sha2::{Sha256, Digest};

pub fn main() {
    // Read inputs
    let user: Address = sp1_zkvm::io::read();
    let reputation_score: u64 = sp1_zkvm::io::read();
    let merkle_root: FixedBytes<32> = sp1_zkvm::io::read();
    let merkle_proof: Vec<FixedBytes<32>> = sp1_zkvm::io::read();
    let path_indices: Vec<bool> = sp1_zkvm::io::read();
    let threshold: u64 = sp1_zkvm::io::read();
    
    // 1. Check threshold
    assert!(reputation_score >= threshold, "Reputation below threshold");
    
    // 2. Compute leaf
    let mut hasher = Sha256::new();
    hasher.update(user.as_slice());
    hasher.update(&reputation_score.to_le_bytes());
    let leaf: [u8; 32] = hasher.finalize().into();
    
    // 3. Verify Merkle proof
    let mut current = leaf;
    for (i, sibling) in merkle_proof.iter().enumerate() {
        let mut hasher = Sha256::new();
        if path_indices[i] {
            hasher.update(sibling.as_slice());
            hasher.update(&current);
        } else {
            hasher.update(&current);
            hasher.update(sibling.as_slice());
        }
        current = hasher.finalize().into();
    }
    
    assert_eq!(current, merkle_root.as_slice(), "Invalid Merkle proof");
    
    // Commit public values
    sp1_zkvm::io::commit(&user);
    sp1_zkvm::io::commit(&reputation_score);
    sp1_zkvm::io::commit(&merkle_root);
    sp1_zkvm::io::commit(&threshold);
}
