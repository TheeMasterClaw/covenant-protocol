from typing import Any, Dict, List, Optional

from web3 import Web3


MORPHEUS_AGENT_REGISTRY_ABI = [
    {"inputs": [{"name": "tokenId", "type": "uint256"}], "name": "ownerOf", "outputs": [{"name": "", "type": "address"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "tokenId", "type": "uint256"}], "name": "getAgentCapabilities", "outputs": [{"name": "", "type": "bytes32[]"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "tokenId", "type": "uint256"}], "name": "getAgentReputation", "outputs": [{"name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "tokenId", "type": "uint256"}], "name": "getAgentMetadataURI", "outputs": [{"name": "", "type": "string"}], "stateMutability": "view", "type": "function"},
]

MORPHEUS_COMPUTE_REGISTRY_ABI = [
    {"inputs": [], "name": "getProviderCount", "outputs": [{"name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "index", "type": "uint256"}], "name": "providers", "outputs": [{"name": "", "type": "address"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "provider", "type": "address"}], "name": "getProviderCapabilities", "outputs": [{"name": "", "type": "bytes32[]"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "provider", "type": "address"}], "name": "getProviderStake", "outputs": [{"name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"name": "provider", "type": "address"}], "name": "isProviderActive", "outputs": [{"name": "", "type": "bool"}], "stateMutability": "view", "type": "function"},
]


class MorpheusAdapter:
    """Bridge to Morpheus Smart Agent NFT and compute marketplace."""

    def __init__(
        self,
        rpc_url: str,
        agent_registry: str,
        compute_registry: str,
    ):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.agent_registry = self.w3.eth.contract(
            address=Web3.to_checksum_address(agent_registry),
            abi=MORPHEUS_AGENT_REGISTRY_ABI,
        )
        self.compute_registry = self.w3.eth.contract(
            address=Web3.to_checksum_address(compute_registry),
            abi=MORPHEUS_COMPUTE_REGISTRY_ABI,
        )

    async def get_agent_nft(self, token_id: int) -> Dict[str, Any]:
        """Fetch Smart Agent NFT details."""
        try:
            owner = self.agent_registry.functions.ownerOf(token_id).call()
            caps = self.agent_registry.functions.getAgentCapabilities(token_id).call()
            rep = self.agent_registry.functions.getAgentReputation(token_id).call()
            metadata = self.agent_registry.functions.getAgentMetadataURI(token_id).call()
            return {
                "token_id": token_id,
                "owner": owner,
                "capabilities": [c.hex() for c in caps],
                "reputation": rep,
                "metadata_uri": metadata,
                "exists": True,
            }
        except Exception as e:
            return {"token_id": token_id, "exists": False, "error": str(e)}

    async def verify_nft_ownership(self, token_id: int, expected_owner: str) -> bool:
        """Verify that an address owns a specific Smart Agent NFT."""
        try:
            owner = self.agent_registry.functions.ownerOf(token_id).call()
            return owner.lower() == expected_owner.lower()
        except Exception:
            return False

    async def find_compute_providers(
        self,
        capability: Optional[str] = None,
        min_stake: int = 0,
    ) -> List[Dict[str, Any]]:
        """Find compute providers matching criteria."""
        count = self.compute_registry.functions.getProviderCount().call()
        providers = []

        for i in range(count):
            try:
                addr = self.compute_registry.functions.providers(i).call()
                if not self.compute_registry.functions.isProviderActive(addr).call():
                    continue

                stake = self.compute_registry.functions.getProviderStake(addr).call()
                if stake < min_stake:
                    continue

                caps = self.compute_registry.functions.getProviderCapabilities(addr).call()
                cap_strs = [c.hex() for c in caps]

                if capability and capability not in cap_strs:
                    continue

                providers.append({
                    "address": addr,
                    "stake": stake,
                    "capabilities": cap_strs,
                })
            except Exception:
                continue

        return sorted(providers, key=lambda x: x["stake"], reverse=True)

    async def match_agent_to_compute(self, token_id: int) -> List[Dict[str, Any]]:
        """Find compute providers that can run a specific Smart Agent."""
        agent = await self.get_agent_nft(token_id)
        if not agent["exists"]:
            return []

        providers = []
        for cap in agent["capabilities"]:
            cap_providers = await self.find_compute_providers(capability=cap)
            providers.extend(cap_providers)

        # Deduplicate by address
        seen = set()
        unique = []
        for p in providers:
            if p["address"] not in seen:
                seen.add(p["address"])
                unique.append(p)
        return unique
