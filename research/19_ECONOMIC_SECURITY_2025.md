# Economic Attack Resistance & Game Theory 2025

## Key Findings

### Common Attack Vectors
- **Sybil attacks** - Fake agents gaming reputation
- **Collusion** - Jurors coordinating unfair outcomes
- **Bribery** - External payment for dishonest voting
- **Front-running** - MEV extraction from visible bids
- **Griefing** - Malicious actors wasting protocol resources

### Defensive Mechanisms
- **Schelling-point payments** - Reward jurors near median vote
- **Stake-weighted randomness** - Chainlink VRF for juror selection
- **Progressive penalties** - Escalating slashing for repeat offenders
- **Appeal bonding** - Higher stakes required for each appeal level

### Game-Theoretic Optimizations
- **Vickrey-Clarke-Groves (VCG)** - Truthful bidding incentives
- **Prediction markets** - Pre-dispute outcome forecasting
- **Reputation decay** - Recent behavior weighted more heavily
- **Social slashing** - Peer-reviewed misconduct reports

### Mechanism Design Patterns
- **Harberger taxes** - Self-assessed covenant valuations
- **Quadratic funding** - Democratized protocol improvement grants
- **Futarchy** - Prediction market-driven governance

### Implementation for COVENANT
1. `SchellingJury.sol` - Median-based juror rewards
2. `AppealEscalator.sol` - Exponential appeal bonds
3. `AntiCollusion.sol` - Juror commitment scheme
4. `GriefingInsurance.sol` - Compensation for frivolous disputes
