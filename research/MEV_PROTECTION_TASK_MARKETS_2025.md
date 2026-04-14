# MEV Protection Strategies for On-Chain Task Markets & Auctions (2025)
## Research Report for COVENANT Protocol

---

## Executive Summary

Public on-chain bidding in task markets exposes agents and users to severe MEV extraction: front-running (bid sniping), sandwich attacks on bid adjustments, and time-bandit attacks on auction settlement. This report analyzes five battle-tested MEV-resistant mechanisms and maps them to concrete modifications for COVENANT's `TaskAuction.sol` and `OptimizedTaskMarket.sol`.

---

## 1) Commit-Reveal Schemes for Bid Submission

### Mechanism
Bidders submit a cryptographic hash (commitment) of their bid parameters during a `COMMIT` phase. Only after the commit window closes do they reveal the plaintext bid + a unique salt. The contract verifies `keccak256(abi.encode(bidder, amount, salt)) == commitment`.

**Why it works:** Transaction contents are opaque to searchers during the commit phase. Front-running requires knowing the bid, which is impossible until reveal.

### Real-World Implementations
- **Gnosis Auction (EasyAuction)**: Uses encrypted limit orders placed during an order-placement window.
- **ENS (Ethereum Name Service)**: Classic commit-reveal for name auctions.
- **Chainlink VRF**: Commit-reveal pattern for verifiable randomness.

### COVENANT Modification
Add two-phase bidding to `OptimizedTaskMarket.sol`:
- `bidCommit(uint256 taskId, bytes32 commitment)` — stores commitment with timestamp.
- `bidReveal(...)` — verifies hash, stores actual bid.

---

## 2) Sealed-Bid Vickrey Auctions

### Mechanism
Bidders submit sealed bids. The highest bidder wins but pays the *second-highest* price.

**MEV resistance:** Since bids are sealed, there is no sniping war.

### Real-World Implementations
- **Gnosis Auction (EasyAuction)**: Uniform-clearing-price batch auction.
- **Secret Network / Shade Protocol**: Uses TEEs to hide bids.

---

## 3) Time-Weighted Average Pricing (TWAP) for Task Valuation

### Mechanism
A TWAP oracle smooths historical clearing prices over a rolling window.

### Real-World Implementations
- **Uniswap V3 TWAP Oracle**: `observe()` function returns time-weighted geometric mean price.
- **Chainlink Market Hours**: Uses TWAP for liquidation thresholds.

---

## 4) MEV-Share / Flashbots Protect Integration

### Mechanism
**Flashbots Protect** provides a private RPC endpoint that submits transactions directly to Flashbots builders.

### Real-World Implementations
- **CoW Protocol**: All orders sent to private mempool before batching.
- **UniswapX / 1inch Fusion**: Uses Dutch auctions resolved via Flashbots bundles.
- **Sorella (Angstrom)**: Integrates with Flashbots MEV-Share.

---

## 5) Fully Homomorphic Encryption (FHE) for Private Bids

### Mechanism
FHE allows arithmetic operations on encrypted values without decrypting them.

### Real-World Implementations (2025)
- **Zama fhEVM**: Production-ready FHE smart contract platform.
- **Fhenix**: FHE-based L2 using threshold BGN encryption.
- **Sunscreen / Optalysys**: FHE compilers for Solidity.

---

## Recommended Roadmap

| Priority | Mechanism | Target Contract | Effort | Impact |
|----------|-----------|-----------------|--------|--------|
| 1 | Commit-Reveal Bidding | `OptimizedTaskMarket.sol` | Low | High |
| 2 | Flashbots Protect RPC | Frontend/SDK | Low | High |
| 3 | Sealed-Bid Vickrey | `TaskAuction.sol` | Medium | High |
| 4 | TWAP Oracle | `TaskValuationOracle.sol` | Medium | Medium |
| 5 | FHE Private Bids | `TaskAuctionFHE.sol` | High | Very High |

