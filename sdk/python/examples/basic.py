"""Basic usage example for the COVENANT Python SDK."""

import os
from web3 import Web3
from covenant_sdk import CovenantSDK, SdkConfig, ContractAddresses


def main():
    config = SdkConfig(
        rpc_url=os.environ.get("RPC_URL", "http://localhost:8545"),
        chain_id=int(os.environ.get("CHAIN_ID", "31337")),
        private_key=os.environ.get("PRIVATE_KEY", "0x..."),
        contract_addresses=ContractAddresses(
            covenant_factory="0x...",
            covenant_registry="0x...",
            covenant_implementation="0x...",
            covenant_proxy="0x...",
            covenant_events="0x...",
            task_market="0x...",
            task_auction="0x...",
            task_escrow="0x...",
            task_review="0x...",
            task_dispute="0x...",
            dispute_dao="0x...",
            dispute_resolution="0x...",
            dispute_jury="0x...",
            dispute_voting="0x...",
            dispute_evidence="0x...",
            dispute_appeal="0x...",
            reputation_stake="0x...",
            reputation_oracle="0x...",
            reputation_boost="0x...",
            reputation_decay="0x...",
            reputation_history="0x...",
            covenant_governor="0x...",
            covenant_timelock="0x...",
            covenant_token="0x...",
            covenant_treasury="0x...",
            covenant_bridge="0x...",
            message_relayer="0x...",
            message_verifier="0x...",
            covenant_multi_sig="0x...",
            zk_verifier="0x...",
            coven_token="0x...",
            reward_distributor="0x...",
            staking_pool="0x...",
        ),
    )

    sdk = CovenantSDK(config)
    print("=== COVENANT Python SDK Examples ===\n")

    # Get account info
    address = sdk.get_address()
    balance = sdk.get_balance()
    print(f"Connected as: {address}")
    print(f"Balance: {Web3.from_wei(balance, 'ether')} ETH\n")

    # Example 1: Create a Covenant
    print("1. Creating a Covenant...")
    try:
        salt = Web3.keccak(text="example-covenant")
        init_data = "0x"
        predicted = sdk.covenant_factory.predict_covenant_address(salt, init_data)
        print(f"Predicted address: {predicted}")
        
        tx = sdk.covenant_factory.create_covenant(salt, init_data)
        receipt = tx.wait()
        print(f"Covenant created! Status: {receipt['status']}\n")
    except Exception as e:
        print(f"Failed: {e}\n")

    # Example 2: Submit a Task
    print("2. Submitting a Task...")
    try:
        tx = sdk.task_market.create_task(
            covenant_id=1,
            reward=Web3.to_wei(0.5, "ether"),
            reward_token="0x0000000000000000000000000000000000000000",
            deadline=1699999999,
            metadata_hash=Web3.keccak(text="task-description"),
            value=Web3.to_wei(0.5, "ether")
        )
        receipt = tx.wait()
        print(f"Task submitted! Status: {receipt['status']}\n")
    except Exception as e:
        print(f"Failed: {e}\n")

    # Example 3: Stake Reputation
    print("3. Staking Reputation...")
    try:
        tx = sdk.reputation_stake.stake(
            amount=Web3.to_wei(100, "ether"),
            lock_duration=2592000
        )
        receipt = tx.wait()
        print(f"Staked! Status: {receipt['status']}")
        
        stake_info = sdk.reputation_stake.get_stake_info(address)
        print(f"Stake info: {stake_info}\n")
    except Exception as e:
        print(f"Failed: {e}\n")

    # Example 4: File a Dispute
    print("4. Filing a Dispute...")
    try:
        tx = sdk.dispute_appeal.file_appeal(dispute_id=1, value=Web3.to_wei(0.5, "ether"))
        receipt = tx.wait()
        print(f"Dispute filed! Status: {receipt['status']}\n")
    except Exception as e:
        print(f"Failed: {e}\n")

    # Example 5: Read operations
    print("5. Reading Contract State...")
    try:
        total_covenants = sdk.covenant_registry.total_covenants()
        print(f"Total covenants: {total_covenants}")
        
        dispute_params = sdk.dispute_dao.get_params()
        print(f"Dispute params: {dispute_params}")
        
        print(f"Current block: {sdk.get_block_number()}\n")
    except Exception as e:
        print(f"Failed: {e}\n")

    print("=== Examples Complete ===")


if __name__ == "__main__":
    main()
