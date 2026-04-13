"""Type definitions for the COVENANT SDK."""

from dataclasses import dataclass
from typing import Optional, List, Dict, Any, NewType
from enum import IntEnum
from eth_typing import Address, ChecksumAddress, HexStr

EthereumAddress = NewType("EthereumAddress", ChecksumAddress)
Bytes32 = NewType("Bytes32", HexStr)
Bytes = NewType("Bytes", HexStr)


@dataclass
class ContractAddresses:
    """Contract addresses for COVENANT Protocol."""
    covenant_factory: EthereumAddress
    covenant_registry: EthereumAddress
    covenant_implementation: EthereumAddress
    covenant_proxy: EthereumAddress
    covenant_events: EthereumAddress
    task_market: EthereumAddress
    task_auction: EthereumAddress
    task_escrow: EthereumAddress
    task_review: EthereumAddress
    task_dispute: EthereumAddress
    dispute_dao: EthereumAddress
    dispute_resolution: EthereumAddress
    dispute_jury: EthereumAddress
    dispute_voting: EthereumAddress
    dispute_evidence: EthereumAddress
    dispute_appeal: EthereumAddress
    reputation_stake: EthereumAddress
    reputation_oracle: EthereumAddress
    reputation_boost: EthereumAddress
    reputation_decay: EthereumAddress
    reputation_history: EthereumAddress
    covenant_governor: EthereumAddress
    covenant_timelock: EthereumAddress
    covenant_token: EthereumAddress
    covenant_treasury: EthereumAddress
    covenant_bridge: EthereumAddress
    message_relayer: EthereumAddress
    message_verifier: EthereumAddress
    covenant_multi_sig: EthereumAddress
    zk_verifier: EthereumAddress
    coven_token: EthereumAddress
    reward_distributor: EthereumAddress
    staking_pool: EthereumAddress


@dataclass
class SdkConfig:
    """Configuration for the COVENANT SDK."""
    rpc_url: str
    chain_id: int
    contract_addresses: ContractAddresses
    private_key: Optional[str] = None


# Enums
class CovenantState(IntEnum):
    Draft = 0
    Active = 1
    Paused = 2
    Resolved = 3
    Terminated = 4


class TaskStatus(IntEnum):
    Open = 0
    Assigned = 1
    Submitted = 2
    Completed = 3
    Disputed = 4
    Cancelled = 5


class EscrowState(IntEnum):
    Pending = 0
    Funded = 1
    Released = 2
    Refunded = 3
    Disputed = 4


class TaskDisputeStatus(IntEnum):
    Open = 0
    Evidence = 1
    Voting = 2
    Resolved = 3
    Appealed = 4


class TaskDisputeOutcome(IntEnum):
    Pending = 0
    InitiatorWins = 1
    RespondentWins = 2
    Split = 3


class ResolutionOutcome(IntEnum):
    Pending = 0
    InitiatorWins = 1
    RespondentWins = 2
    Split = 3
    Dismissed = 4


class AppealStatus(IntEnum):
    Pending = 0
    Upheld = 1
    Overturned = 2
    Rejected = 3


# Struct Data Classes
@dataclass
class Task:
    id: int
    covenant_id: int
    creator: EthereumAddress
    assignee: EthereumAddress
    reward: int
    reward_token: EthereumAddress
    deadline: int
    status: TaskStatus
    metadata_hash: Bytes32


@dataclass
class Auction:
    task_id: int
    start_price: int
    end_price: int
    start_time: int
    duration: int
    highest_bidder: EthereumAddress
    highest_bid: int
    settled: bool


@dataclass
class Escrow:
    task_id: int
    amount: int
    token: EthereumAddress
    payer: EthereumAddress
    payee: EthereumAddress
    state: EscrowState


@dataclass
class Review:
    review_id: int
    task_id: int
    reviewer: EthereumAddress
    reviewee: EthereumAddress
    rating: int
    comment_hash: Bytes32
    created_at: int


@dataclass
class TaskDisputeRecord:
    dispute_id: int
    task_id: int
    initiator: EthereumAddress
    respondent: EthereumAddress
    initiated_at: int
    status: TaskDisputeStatus
    outcome: TaskDisputeOutcome
    reason_hash: Bytes32


@dataclass
class StakeInfo:
    amount: int
    staked_at: int
    unlock_time: int
    locked: bool


@dataclass
class OracleData:
    data_hash: Bytes32
    timestamp: int
    confidence: int
    source: EthereumAddress


@dataclass
class Boost:
    amount: int
    expires_at: int
    reason: Bytes32
    active: bool


@dataclass
class ReputationSnapshot:
    timestamp: int
    score: int
    context: Bytes32


@dataclass
class DisputeParams:
    min_stake: int
    voting_period: int
    quorum: int
    appeal_threshold: int


@dataclass
class Juror:
    account: EthereumAddress
    stake: int
    selection_score: int
    active: bool


@dataclass
class Vote:
    voter: EthereumAddress
    choice: int
    weight: int
    timestamp: int


@dataclass
class Evidence:
    evidence_id: int
    dispute_id: int
    submitter: EthereumAddress
    evidence_hash: Bytes32
    metadata_hash: Bytes32
    submitted_at: int


@dataclass
class Appeal:
    appeal_id: int
    dispute_id: int
    appellant: EthereumAddress
    bond: int
    appealed_at: int
    status: AppealStatus


@dataclass
class Proposal:
    id: int
    proposer: EthereumAddress
    description: str
    call_data: Bytes
    target: EthereumAddress
    for_votes: int
    against_votes: int
    abstain_votes: int
    start_time: int
    end_time: int
    executed: bool
    canceled: bool


@dataclass
class BridgeMessage:
    target_chain: int
    target_contract: EthereumAddress
    payload: Bytes
    nonce: int


@dataclass
class RelayJob:
    message_id: int
    target_chain: int
    payload: Bytes
    fee: int
    relayer: EthereumAddress
    completed: bool


@dataclass
class VerifiedMessage:
    message_hash: Bytes32
    signature: Bytes
    signer: EthereumAddress
    verified_at: int
    valid: bool


@dataclass
class Transaction:
    to: EthereumAddress
    value: int
    data: Bytes
    executed: bool
    confirmation_count: int


@dataclass
class Operation:
    target: EthereumAddress
    value: int
    data: Bytes
    scheduled_at: int
    delay: int
    executed: bool


@dataclass
class ZKProof:
    a: List[int]
    b: List[List[int]]
    c: List[int]


@dataclass
class Tokenomics:
    max_supply: int
    total_minted: int
    inflation_rate: int
    last_mint_time: int


@dataclass
class Stake:
    amount: int
    reward_debt: int
    lock_end: int
    multiplier: int


@dataclass
class Distribution:
    token: EthereumAddress
    amount: int
    start_time: int
    end_time: int
    claimed: int


# Transaction and Receipt types
@dataclass
class TransactionReceipt:
    block_hash: Bytes32
    block_number: int
    contract_address: Optional[EthereumAddress]
    cumulative_gas_used: int
    effective_gas_price: int
    from_address: EthereumAddress
    gas_used: int
    logs: List[Dict[str, Any]]
    status: str  # "success" or "reverted"
    to_address: EthereumAddress
    transaction_hash: Bytes32
    transaction_index: int
