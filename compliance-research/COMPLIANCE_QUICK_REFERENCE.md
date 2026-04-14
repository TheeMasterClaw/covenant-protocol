# COVENANT Compliance Quick Reference

## Regulatory Risk Matrix

| Regulation | Risk Level | Affected Components | Primary Mitigation |
|------------|-----------|---------------------|-------------------|
| FATF Travel Rule | Medium | Cross-chain bridges, high-value verified pools | Sygna Bridge integration at relayer level |
| AML/KYC | Medium-High | All user-facing interfaces, verified pools | ZK-credentials via Synaps/zkMe + ComplianceRegistry |
| SEC Securities | High | Governance token, staking rewards | Separate COV-GOV (no fees) from COV-UTIL (work token) |
| CFTC Commodities | Low | Staking, derivatives | No leverage, no guaranteed yield, use third-party bridges |
| GDPR | Medium | Frontend, AgentRegistry metadata | Store only metadataHash on-chain, DPAs with providers |
| EU AI Act | Medium-High | DisputeDAO, AI arbitration | Ban AI from final arbitration, human-in-the-loop |

## Dual-Pool Model

```
User ──► Frontend (geofencing + sanctions screening)
            │
            ├──► Permissionless Pool
            │    • No KYC/AML checks
            │    • Standard contracts
            │    • Always available
            │    • Lower limits
            │
            └──► Verified Pool
                 • Requires ComplianceRegistry credential
                 • Higher staking/task limits
                 • Travel Rule enforced >$1,000
                 • Mandatory for institutional users
```

## Token Structure

| Token | Purpose | Fee Rights | Regulatory Risk |
|-------|---------|------------|----------------|
| COV-GOV | Protocol governance, parameter votes | No | Low |
| COV-UTIL | Work token for tasks, agent reg, disputes | No | Low |
| veCOV | Voting escrow, reputation boost | No | Low |

All protocol revenue flows to DAO treasury. Token holders vote on allocation.

## Key Contract Addresses (To Be Deployed)

| Contract | Purpose |
|----------|---------|
| `ComplianceRegistry` | On-chain compliance attestations without PII |
| `VerifiedCovenantFactory` | Compliance-gated covenant creation |
| `VerifiedTaskMarket` | Compliance-gated task marketplace |
| `VerifiedReputationStake` | Compliance-gated agent registration |

## Recommended Provider Stack

| Function | Primary Provider | Backup Provider |
|----------|-----------------|-----------------|
| Sanctions Screening | Chainalysis KYT | Elliptic |
| KYC/AML (ZK) | Synaps zkKYC | zkMe |
| Travel Rule | Sygna Bridge | OpenVASP |
| Identity Credentials | Polygon ID | World ID v2 |
| Legal Entity | Swiss Foundation | Cayman Foundation |

## GDPR Action Items

- [ ] Replace `metadataURI` with `metadataHash` in `AgentProfile`
- [ ] Implement 90-day IP log retention policy
- [ ] Sign DPAs with Vercel, Infura/Alchemy, Synaps/Sumsub
- [ ] Appoint Data Protection Officer (DPO)
- [ ] Publish privacy policy on frontend
- [ ] Build data deletion request endpoint

## SEC De-Risking Checklist

- [ ] No automatic fee distributions to token holders
- [ ] No guaranteed staking APY
- [ ] Governance token has no dividend rights
- [ ] Treasury funds allocated by DAO vote only
- [ ] Clear separation between protocol and development company
- [ ] No promises of token price appreciation

## EU AI Act Checklist

- [ ] AI agents cannot vote in DisputeDAO without human confirmation
- [ ] AI involvement disclosed in all covenant/task negotiations
- [ ] Technical documentation maintained for all AI integrations
- [ ] Core smart contracts remain deterministic (no ML on-chain)
- [ ] Risk management process documented

## Implementation Priority

1. **Immediate (Q2 2025):** Frontend geofencing, Chainalysis sanctions screening, legal entity setup
2. **Short-term (Q3 2025):** Deploy ComplianceRegistry, integrate Synaps, launch verified pools
3. **Medium-term (Q4 2025):** Travel Rule integration for cross-chain
4. **Long-term (Q1-Q2 2026):** Governance token launch, AI Act documentation
