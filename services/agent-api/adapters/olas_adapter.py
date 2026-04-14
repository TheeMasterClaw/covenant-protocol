import json
from typing import Any, Dict, List

import aiohttp
from eth_abi import decode
from web3 import Web3


class OlasAdapter:
    """Bridge to Autonolas registries and ACN."""

    SERVICE_REGISTRY_ABI = [
        {"inputs": [{"name": "serviceId", "type": "uint256"}], "name": "mapServices", "outputs": [{"components": [{"name": "securityDeposit", "type": "uint256"}, {"name": "multisig", "type": "address"}], "name": "service", "type": "tuple"}], "stateMutability": "view", "type": "function"},
        {"inputs": [{"name": "serviceId", "type": "uint256"}], "name": "getServiceState", "outputs": [{"name": "state", "type": "uint8"}], "stateMutability": "view", "type": "function"},
    ]

    AGENT_REGISTRY_ABI = [
        {"inputs": [{"name": "agentId", "type": "uint256"}], "name": "getAgent", "outputs": [{"components": [{"name": "developer", "type": "address"}, {"name": "agentHash", "type": "bytes32"}], "name": "agent", "type": "tuple"}], "stateMutability": "view", "type": "function"},
    ]

    def __init__(
        self,
        web3_provider: str,
        service_registry: str,
        agent_registry: str,
        acn_url: str = "",
    ):
        self.w3 = Web3(Web3.HTTPProvider(web3_provider))
        self.service_registry = self.w3.eth.contract(
            address=Web3.to_checksum_address(service_registry),
            abi=self.SERVICE_REGISTRY_ABI,
        )
        self.agent_registry = self.w3.eth.contract(
            address=Web3.to_checksum_address(agent_registry),
            abi=self.AGENT_REGISTRY_ABI,
        )
        self.acn_url = acn_url.rstrip("/") if acn_url else ""

    async def verify_service(self, service_id: int) -> Dict[str, Any]:
        try:
            service = self.service_registry.functions.mapServices(service_id).call()
            state = self.service_registry.functions.getServiceState(service_id).call()
            return {
                "service_id": service_id,
                "safe": service[1],
                "security_deposit": service[0],
                "state": state,
                "verified": state == 4, // 4 = Deployed
            }
        except Exception as e:
            return {"service_id": service_id, "verified": False, "error": str(e)}

    async def verify_agent(self, agent_id: int) -> Dict[str, Any]:
        try:
            agent = self.agent_registry.functions.getAgent(agent_id).call()
            return {
                "agent_id": agent_id,
                "developer": agent[0],
                "agent_hash": agent[1].hex(),
                "verified": agent[0] != "0x0000000000000000000000000000000000000000",
            }
        except Exception as e:
            return {"agent_id": agent_id, "verified": False, "error": str(e)}

    async def send_acn_message(self, agent_address: str, message: Dict[str, Any]) -> Dict[str, Any]:
        if not self.acn_url:
            raise RuntimeError("ACN URL not configured")
        payload = {
            "recipient": agent_address,
            "payload": json.dumps(message),
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.acn_url}/send",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                return await resp.json()
