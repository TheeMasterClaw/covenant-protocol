# Task Type x Oracle Matrix
## Optimal Oracle Selection by Verification Type

## 1. Off-Chain API Call Verification
| Solution | Mechanism | Cost/Call | Latency | Trust Model | Score |
|----------|-----------|-----------|---------|-------------|-------|
| Reclaim | ZK-TLS proof | \/usr/bin/bash.05-0.15 | 2-3 min | Cryptographic | A+ |
| Chainlink Functions | DON execution | \/usr/bin/bash.25-2.00 | 3-5 min | Chainlink DON | A |
| API3 | First-party signed | \/usr/bin/bash.01-0.05 | 1 block | API provider | A (if supported) |
| UMA | Optimistic assertion | \/usr/bin/bash.10 + bond | 2 min-2 hr | Economic | B |
| Tellor | Reporter submission | \/usr/bin/bash.05 + tip | 10 min-12 hr | Staked game | C+ |
| Pyth | Pull model | ~\/usr/bin/bash.001 | 400ms | Publisher | B (financial only) |

## 2. Image/Document Verification
| Solution | Mechanism | Cost | Latency | Best For | Score |
|----------|-----------|------|---------|----------|-------|
| UMA OO | Optimistic + human review | \/usr/bin/bash.10 + bond | 2 hr | Quality assessment | A+ |
| Chainlink Functions | DON compute | \/usr/bin/bash.50-1.50 | 3-5 min | Automated metrics | A |
| Tellor | Community validation | \/usr/bin/bash.10 + tip | 12 hr | Content attestation | B+ |
| Reclaim | TLS proof | \/usr/bin/bash.05 | 2-3 min | API-sourced docs | B |

## 3. Social Media Sentiment Verification
| Solution | Mechanism | Cost/Call | Latency | Data Source | Score |
|----------|-----------|-----------|---------|-------------|-------|
| Reclaim | ZK-TLS (Twitter API) | \/usr/bin/bash.05-0.10 | 2-3 min | Direct API | A+ |
| Chainlink Functions | DON + API | \/usr/bin/bash.25-0.75 | 3-5 min | Any API | A |
| UMA | Optimistic claim | \/usr/bin/bash.10 + bond | 2 min-2 hr | Claim-based | A (qualitative) |
| Tellor | Reporter feed | \/usr/bin/bash.05 + tip | 10 min-12 hr | Community | B |

## 4. Web Scraping Attestation
| Solution | Mechanism | Cost | Latency | Reliability | Score |
|----------|-----------|------|---------|-------------|-------|
| Tellor | Reporter network | \/usr/bin/bash.10 + tip | 10 min-12 hr | Community | A |
| Reclaim | ZK-TLS (if HTTPS) | \/usr/bin/bash.05 | 2-3 min | Cryptographic | A- |
| Chainlink Functions | DON scraping | \/usr/bin/bash.50-2.00 | 3-5 min | Chainlink | B+ |
| UMA | Optimistic claim | \/usr/bin/bash.10 + bond | 2 hr | Economic | B |
