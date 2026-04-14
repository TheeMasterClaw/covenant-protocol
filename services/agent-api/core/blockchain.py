import json
import os
from typing import Any, Dict, Optional

from web3 import Web3
from eth_account.datastructures import SignedTransaction

from app.config import settings

_COVENANT_RPC_URL = os.getenv("COVENANT_RPC_URL", settings.WEB3_RPC_URL or "https://testrpc.xlayer.tech")
_AGENT_REGISTRY_ADDRESS = os.getenv("AGENT_REGISTRY_ADDRESS", "")
_COVENANT_FACTORY_ADDRESS = os.getenv("COVENANT_FACTORY_ADDRESS", "")
_TASK_MARKET_ADDRESS = os.getenv("TASK_MARKET_ADDRESS", "")
_REPUTATION_STAKE_ADDRESS = os.getenv("REPUTATION_STAKE_ADDRESS", "")
_REPUTATION_AGGREGATOR_ADDRESS = os.getenv("REPUTATION_AGGREGATOR_ADDRESS", "")
_AUTONOMOUS_EXECUTOR_ADDRESS = os.getenv("AUTONOMOUS_EXECUTOR_ADDRESS", "")
_PRIVATE_KEY = os.getenv("EXECUTOR_PRIVATE_KEY", os.getenv("PRIVATE_KEY", ""))

_AUTONOMOUS_EXECUTOR_ABI = json.loads(
    """
    [
      {
        "inputs": [
          {"internalType": "address", "name": "covenant", "type": "address"},
          {"internalType": "bytes32", "name": "proofHash", "type": "bytes32"}
        ],
        "name": "submitIntent",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "covenant", "type": "address"},
          {"internalType": "bytes32", "name": "proofHash", "type": "bytes32"},
          {"internalType": "bytes", "name": "validationData", "type": "bytes"}
        ],
        "name": "verifyExecution",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "inputs": [
          {"internalType": "address", "name": "", "type": "address"}
        ],
        "name": "intents",
        "outputs": [
          {"internalType": "address", "name": "executor", "type": "address"},
          {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
          {"internalType": "bytes32", "name": "proofHash", "type": "bytes32"},
          {"internalType": "bool", "name": "executed", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ]
    """
)


def _load_abi_from_file(path: str) -> Any:
    with open(path, "r") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    return data.get("abi", [])


def _get_w3() -> Optional[Web3]:
    if not _COVENANT_RPC_URL:
        return None
    w3 = Web3(Web3.HTTPProvider(_COVENANT_RPC_URL))
    if not w3.is_connected():
        return None
    return w3


def _get_contract(w3: Web3, address: str, abi: Any):
    if not address:
        return None
    return w3.eth.contract(address=Web3.to_checksum_address(address), abi=abi)


def _agent_registry_abi() -> Any:
    try:
        return _load_abi_from_file("/home/azureuser/covenant/frontend/src/abis/AgentRegistry.json")
    except Exception:
        pass
    try:
        return _load_abi_from_file("/home/azureuser/covenant/artifacts/AgentRegistry.sol/AgentRegistry.json")
    except Exception:
        pass
    return []


def _reputation_stake_abi() -> Any:
    try:
        return _load_abi_from_file("/home/azureuser/covenant/frontend/src/abis/ReputationStake.json")
    except Exception:
        pass
    try:
        return _load_abi_from_file("/home/azureuser/covenant/artifacts/ReputationStake.sol/ReputationStake.json")
    except Exception:
        pass
    return []


def _reputation_aggregator_abi() -> Any:
    try:
        return _load_abi_from_file("/home/azureuser/covenant/artifacts/ReputationAggregator.sol/ReputationAggregator.json")
    except Exception:
        pass
    return []


def check_agent_exists_on_chain(agent_address: str) -> bool:
    w3 = _get_w3()
    if not w3 or not _AGENT_REGISTRY_ADDRESS:
        return False
    abi = _agent_registry_abi()
    contract = _get_contract(w3, _AGENT_REGISTRY_ADDRESS, abi)
    if not contract:
        return False
    try:
        result = contract.functions.agents(Web3.to_checksum_address(agent_address)).call()
        if isinstance(result, (list, tuple)) and len(result) >= 4:
            return bool(result[3])
        if isinstance(result, dict):
            return bool(result.get("isActive", False))
        return False
    except Exception:
        return False


def get_on_chain_reputation(agent_address: str) -> Dict[str, Any]:
    w3 = _get_w3()
    if not w3:
        raise RuntimeError("Blockchain RPC not available")

    sources = []
    score = 0.0

    if _REPUTATION_STAKE_ADDRESS:
        abi = _reputation_stake_abi()
        contract = _get_contract(w3, _REPUTATION_STAKE_ADDRESS, abi)
        if contract:
            try:
                result = contract.functions.agents(Web3.to_checksum_address(agent_address)).call()
                if isinstance(result, (list, tuple)) and len(result) >= 2:
                    raw_score = int(result[1])
                    score = float(raw_score)
                    sources.append({
                        "platform": "ReputationStake",
                        "score": raw_score,
                        "weight": 1.0,
                    })
                elif isinstance(result, dict):
                    raw_score = int(result.get("reputationScore", 0))
                    score = float(raw_score)
                    sources.append({
                        "platform": "ReputationStake",
                        "score": raw_score,
                        "weight": 1.0,
                    })
            except Exception:
                pass

    if _REPUTATION_AGGREGATOR_ADDRESS:
        abi = _reputation_aggregator_abi()
        contract = _get_contract(w3, _REPUTATION_AGGREGATOR_ADDRESS, abi)
        if contract:
            try:
                agent_hash = Web3.keccak(text=agent_address).hex()
                agg = contract.functions.aggregatedReputation(agent_hash).call()
                agg_score = int(agg)
                if agg_score > 0:
                    sources.append({
                        "platform": "ReputationAggregator",
                        "score": agg_score,
                        "weight": 0.5,
                    })
            except Exception:
                pass

    if not sources:
        raise RuntimeError("No on-chain reputation source available or configured")

    return {
        "score": score,
        "sources": sources,
    }


def submit_intent_on_chain(
    covenant_address: str,
    proof_hash: str,
    value_eth: float = 0.0,
) -> str:
    w3 = _get_w3()
    if not w3:
        raise RuntimeError("Blockchain RPC not available")
    if not _AUTONOMOUS_EXECUTOR_ADDRESS:
        raise RuntimeError("AUTONOMOUS_EXECUTOR_ADDRESS not configured")
    if not _PRIVATE_KEY:
        raise RuntimeError("No private key configured (EXECUTOR_PRIVATE_KEY or PRIVATE_KEY)")

    contract = _get_contract(w3, _AUTONOMOUS_EXECUTOR_ADDRESS, _AUTONOMOUS_EXECUTOR_ABI)
    if not contract:
        raise RuntimeError("Failed to load AutonomousExecutor contract")

    min_stake = w3.to_wei(0.001, "ether")
    value_wei = w3.to_wei(value_eth, "ether")
    if value_wei < min_stake:
        value_wei = min_stake

    if not proof_hash or proof_hash == "0x":
        proof_hash = "0x" + "0" * 64

    proof_hash_bytes = Web3.to_bytes(hexstr=proof_hash)
    if len(proof_hash_bytes) != 32:
        raise ValueError("proof_hash must be 32 bytes")

    account = w3.eth.account.from_key(_PRIVATE_KEY)
    txn = contract.functions.submitIntent(
        Web3.to_checksum_address(covenant_address),
        proof_hash_bytes,
    ).build_transaction({
        "from": account.address,
        "value": value_wei,
        "nonce": w3.eth.get_transaction_count(account.address),
        "gas": 300000,
        "maxFeePerGas": w3.to_wei("2", "gwei"),
        "maxPriorityFeePerGas": w3.to_wei("1", "gwei"),
        "chainId": w3.eth.chain_id,
    })

    signed: SignedTransaction = account.sign_transaction(txn)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)
    return tx_hash.hex()


def verify_execution_on_chain(
    covenant_address: str,
    proof_hash: str,
    validation_data: bytes = b"",
) -> str:
    w3 = _get_w3()
    if not w3:
        raise RuntimeError("Blockchain RPC not available")
    if not _AUTONOMOUS_EXECUTOR_ADDRESS:
        raise RuntimeError("AUTONOMOUS_EXECUTOR_ADDRESS not configured")
    if not _PRIVATE_KEY:
        raise RuntimeError("No private key configured (EXECUTOR_PRIVATE_KEY or PRIVATE_KEY)")

    contract = _get_contract(w3, _AUTONOMOUS_EXECUTOR_ADDRESS, _AUTONOMOUS_EXECUTOR_ABI)
    if not contract:
        raise RuntimeError("Failed to load AutonomousExecutor contract")

    if not proof_hash or proof_hash == "0x":
        proof_hash = "0x" + "0" * 64
    proof_hash_bytes = Web3.to_bytes(hexstr=proof_hash)
    if len(proof_hash_bytes) != 32:
        raise ValueError("proof_hash must be 32 bytes")

    account = w3.eth.account.from_key(_PRIVATE_KEY)
    txn = contract.functions.verifyExecution(
        Web3.to_checksum_address(covenant_address),
        proof_hash_bytes,
        validation_data,
    ).build_transaction({
        "from": account.address,
        "nonce": w3.eth.get_transaction_count(account.address),
        "gas": 300000,
        "maxFeePerGas": w3.to_wei("2", "gwei"),
        "maxPriorityFeePerGas": w3.to_wei("1", "gwei"),
        "chainId": w3.eth.chain_id,
    })

    signed: SignedTransaction = account.sign_transaction(txn)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)
    return tx_hash.hex()


def get_on_chain_intent(covenant_address: str) -> Optional[Dict[str, Any]]:
    w3 = _get_w3()
    if not w3 or not _AUTONOMOUS_EXECUTOR_ADDRESS:
        return None
    contract = _get_contract(w3, _AUTONOMOUS_EXECUTOR_ADDRESS, _AUTONOMOUS_EXECUTOR_ABI)
    if not contract:
        return None
    try:
        result = contract.functions.intents(Web3.to_checksum_address(covenant_address)).call()
        return {
            "executor": result[0],
            "timestamp": int(result[1]),
            "proof_hash": result[2].hex() if isinstance(result[2], bytes) else result[2],
            "executed": bool(result[3]),
        }
    except Exception:
        return None
