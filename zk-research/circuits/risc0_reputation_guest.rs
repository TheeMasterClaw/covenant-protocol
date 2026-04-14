// RISC0 Guest Program: Batch Reputation Computation
// Located in: risc0/methods/guest/src/bin/reputation_batch.rs

use risc0_zkvm::guest::env;
use alloy_primitives::{Address, U256, FixedBytes};
use sha2::{Sha256, Digest};

fn main() {
    // Read inputs from host
    let previous_root: FixedBytes<32> = env::read();
    let user_updates: Vec<UserUpdate> = env::read();
    let block_height: u64 = env::read();
    
    // Compute new reputation scores
    let mut leaves: Vec<(Address, u64)> = Vec::new();
    
    for update in &user_updates {
        let new_score = compute_reputation_score(
            update.base_score,
            &update.task_completions,
            &update.slashing_events,
            update.stake_amount,
            block_height
        );
        leaves.push((update.user, new_score));
    }
    
    // Build Merkle tree and compute new root
    let new_root = build_merkle_root(&leaves);
    
    // Public outputs committed to journal
    env::commit(&previous_root);
    env::commit(&new_root);
    env::commit(&user_updates.len());
    env::commit(&block_height);
}

#[derive(Clone, serde::Serialize, serde::Deserialize)]
struct UserUpdate {
    user: Address,
    base_score: u64,
    task_completions: Vec<TaskCompletion>,
    slashing_events: Vec<SlashEvent>,
    stake_amount: u64,
}

#[derive(Clone)]
struct TaskCompletion {
    task_id: u64,
    completion_time: u64,
    rating: u8, // 1-5
}

#[derive(Clone)]
struct SlashEvent {
    reason: FixedBytes<32>,
    severity: u8,
    timestamp: u64,
}

fn compute_reputation_score(
    base: u64,
    tasks: &[TaskCompletion],
    slashes: &[SlashEvent],
    stake: u64,
    current_block: u64
) -> u64 {
    // Simple reputation algorithm:
    // Base + (tasks * avg_rating * 10) - (slashes * severity * 100) + (stake / 1e18 * 50)
    let task_points: u64 = tasks.iter().map(|t| t.rating as u64 * 10).sum();
    
    let slash_points: u64 = slashes.iter().map(|s| s.severity as u64 * 100).sum();
    
    let stake_points = stake / 1_000_000_000_000_000_000 * 50; // stake in ETH * 50
    
    let score = base.saturating_add(task_points)
        .saturating_sub(slash_points)
        .saturating_add(stake_points);
    
    score.min(100_000) // Cap at 100k
}

fn build_merkle_root(leaves: &[(Address, u64)]) -> FixedBytes<32> {
    let mut hashes: Vec<[u8; 32]> = leaves.iter()
        .map(|(addr, score)| {
            let mut hasher = Sha256::new();
            hasher.update(addr.as_slice());
            hasher.update(&score.to_le_bytes());
            hasher.finalize().into()
        })
        .collect();
    
    // Pad to power of 2
    while hashes.len() & (hashes.len() - 1) != 0 {
        hashes.push([0u8; 32]);
    }
    
    // Build tree
    while hashes.len() > 1 {
        let mut next_level = Vec::new();
        for i in (0..hashes.len()).step_by(2) {
            let mut hasher = Sha256::new();
            hasher.update(&hashes[i]);
            hasher.update(&hashes[i + 1]);
            next_level.push(hasher.finalize().into());
        }
        hashes = next_level;
    }
    
    FixedBytes::from(hashes[0])
}
