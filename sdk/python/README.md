# covenant-sdk

Python SDK for COVENANT Protocol - A decentralized agreement framework.

## Installation

```bash
pip install covenant-sdk
# or with web3
pip install covenant-sdk web3
```

## Quick Start

```python
from covenant_sdk import CovenantSDK, SdkConfig

config = SdkConfig(
    rpc_url="https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY",
    chain_id=11155111,
    private_key="0x...",  # Optional: for write operations
    contract_addresses={
        "covenant_factory": "0x...",
        "covenant_registry": "0x...",
        # ... all addresses
    }
)

sdk = CovenantSDK(config)
```

## Core Features

### Create a Covenant

```python
from web3 import Web3

salt = Web3.keccak(text="my-covenant")
init_data = b""  # Your initialization params
tx = sdk.covenant_factory.create_covenant(salt, init_data)
receipt = tx.wait()
print(f"Covenant created!")
```

### Submit a Task

```python
tx = sdk.task_market.create_task(
    covenant_id=1,
    reward=Web3.to_wei(1.0, "ether"),
    reward_token="0x...",  # or ZERO_ADDRESS for ETH
    deadline=int(time.time()) + 86400,
    metadata_hash=Web3.keccak(text="task-metadata"),
    value=Web3.to_wei(1.0, "ether")
)
receipt = tx.wait()
```

### Stake Reputation

```python
tx = sdk.reputation_stake.stake(
    amount=Web3.to_wei(100, "ether"),
    lock_duration=2592000  # 30 days
)
receipt = tx.wait()
```

### File a Dispute

```python
tx = sdk.dispute_appeal.file_appeal(
    dispute_id=1,
    value=Web3.to_wei(0.5, "ether")  # appeal bond
)
receipt = tx.wait()
```

## Contract Coverage

This SDK supports all 33+ contracts in the COVENANT Protocol:

- **Core**: `CovenantFactory`, `CovenantRegistry`, `CovenantImplementation`, `CovenantProxy`, `CovenantEvents`
- **Task**: `TaskMarket`, `TaskAuction`, `TaskEscrow`, `TaskReview`, `TaskDispute`
- **Dispute**: `DisputeDAO`, `DisputeResolution`, `DisputeJury`, `DisputeVoting`, `DisputeEvidence`, `DisputeAppeal`
- **Reputation**: `ReputationStake`, `ReputationOracle`, `ReputationBoost`, `ReputationDecay`, `ReputationHistory`
- **Governance**: `CovenantGovernor`, `CovenantTimelock`, `CovenantToken`, `CovenantTreasury`
- **Cross-chain**: `CovenantBridge`, `MessageRelayer`, `MessageVerifier`
- **Security**: `CovenantMultiSig`, `ZKVerifier`
- **Tokenomics**: `COVEN`, `RewardDistributor`, `StakingPool`

## Error Handling

```python
from covenant_sdk.exceptions import ContractCallError, TransactionError, ValidationError

try:
    sdk.covenant_factory.create_covenant(salt, init_data)
except ContractCallError as e:
    print(f"Contract call failed: {e}")
except TransactionError as e:
    print(f"Transaction failed: {e}")
except ValidationError as e:
    print(f"Invalid input: {e}")
```

## License

MIT
