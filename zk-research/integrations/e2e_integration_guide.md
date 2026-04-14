# COVENANT ZK Integration Guide

## Deployment Order

### 1. Deploy ZKVerifierV2
```solidity
ZKVerifierV2 verifier = new ZKVerifierV2();
```

### 2. Deploy Verifier Contracts (Per Circuit)
For Groth16, generate verifier with snarkjs:
```bash
# Compile Circom circuit
circom JuryEligibility.circom --r1cs --wasm --sym
snarkjs groth16 setup JuryEligibility.r1cs ptau_final.ptau JuryEligibility_0000.zkey
snarkjs zkey contribute JuryEligibility_0000.zkey JuryEligibility_final.zkey --name="COVENANT" -v
snarkjs zkey export verificationkey JuryEligibility_final.zkey verification_key.json
snarkjs zkey export solidityverifier JuryEligibility_final.zkey VerifierJuryEligibility.sol
```

### 3. Register Verifiers
```solidity
bytes32 JURY_CIRCUIT = keccak256("JuryEligibility_v1");
bytes32 ZKML_CIRCUIT = keccak256("ZKML_Dispute_v1");
bytes32 RISC0_CIRCUIT = keccak256("ReputationBatch_v1");

verifier.setVerifier(JURY_CIRCUIT, address(groth16Verifier), ZKVerifierV2.ProofType.Groth16);
verifier.setVerifier(ZKML_CIRCUIT, address(zkmlVerifier), ZKVerifierV2.ProofType.Groth16);
verifier.setVerifier(RISC0_CIRCUIT, address(risc0Verifier), ZKVerifierV2.ProofType.Risc0Receipt);
```

### 4. Deploy AnonymousJuryPool
```solidity
AnonymousJuryPool juryPool = new AnonymousJuryPool(address(verifier), JURY_CIRCUIT);
```

### 5. Create a Jury Session
```solidity
// reputationRoot comes from RISC0ReputationBatch.currentReputationRoot()
juryPool.createSession(42, reputationRoot, 1000);
```

### 6. Juror Submits Anonymous Vote
```javascript
// Off-chain proof generation (using snarkjs or Noir)
const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    {
        identitySecret: jurorSecret,
        reputationScore: 5000,
        merklePath: path,
        merklePathIndices: indices,
        merkleRoot: root,
        nullifierHash: nullifier,
        disputeId: 42,
        verdict: 1, // PLAINTIFF
        voteCommitment: voteCommitment,
        minReputationThreshold: 1000
    },
    "JuryEligibility.wasm",
    "JuryEligibility_final.zkey"
);

// Submit to contract
juryPool.submitAnonymousVote(
    42,
    publicSignals,
    {
        a: [proof.pi_a[0], proof.pi_a[1]],
        b: [[proof.pi_b[0][0], proof.pi_b[0][1]], [proof.pi_b[1][0], proof.pi_b[1][1]]],
        c: [proof.pi_c[0], proof.pi_c[1]]
    },
    Verdict.PLAINTIFF,
    voteCommitment
);
```

### 7. AI Juror Submits zkML Proof (EZKL)
```python
import ezkl

# Generate proof
settings_path = "dispute_settings.json"
compiled_model_path = "dispute_model.ezkl"
pk_path = "dispute_pk.key"
proof_path = "dispute_proof.pf"

# EZKL pipeline
ezkl.gen_settings(model_path, settings_path)
ezkl.compile_circuit(model_path, compiled_model_path, settings_path)
ezkl.setup(compiled_model_path, vk_path, pk_path, settings_path)
ezkl.prove(
    evidence_embedding_path,
    compiled_model_path,
    pk_path,
    proof_path,
    "evidence"
)

# Extract proof and public inputs for Solidity
```

### 8. Resolve Dispute
```solidity
juryPool.resolveDispute(42);
```

## Gas Estimates (2025 Projections)
- Groth16 verification: ~85k gas (Circom) / ~120k gas (Noir UltraPlonk)
- RISC0 seal verification: ~280k gas (STARK-to-SNARK wrapper)
- SP1 proof verification: ~200k gas
- Anonymous vote submission: ~110k gas (including nullifier storage)
- zkML proof verification: ~150k gas (EZKL Groth16)

## Security Checklist
- [ ] MPC trusted setup completed for Groth16 circuits
- [ ] Nullifier mapping prevents double-voting
- [ ] Merkle roots updated atomically with batch proofs
- [ ] Model hashes whitelisted before AI juror participation
- [ ] Vote commitments bind to verdict to prevent vote switching
