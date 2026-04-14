import json
from typing import Any, Dict, List, Optional

import aiohttp


class ElizaAdapter:
    """Bridge between COVENANT Agent API and ElizaOS runtime."""

    def __init__(
        self,
        eliza_url: str,
        factory_address: str,
        rpc_url: str,
        registry,
        reputation_api=None,
    ):
        self.eliza_url = eliza_url.rstrip("/")
        self.factory_address = factory_address
        self.rpc_url = rpc_url
        self.registry = registry
        self.reputation_api = reputation_api

    async def create_character_config(self, agent_id: str, wallet: str) -> Dict[str, Any]:
        agent = self.registry.get(agent_id)
        reputation = 0
        if self.reputation_api:
            reputation = await self.reputation_api.get_score(wallet)
        return {
            "name": agent.get("name", "CovenantAgent"),
            "clients": ["telegram", "discord", "direct"],
            "modelProvider": "openrouter",
            "settings": {
                "secrets": {
                    "COVENANT_WALLET_ADDRESS": wallet,
                    "COVENANT_FACTORY": self.factory_address,
                    "COVENANT_RPC_URL": self.rpc_url,
                },
                "covenant": {
                    "reputation": reputation,
                    "capabilities": agent.get("capabilities", []),
                    "agent_id": agent_id,
                },
            },
            "plugins": ["@covenant/plugin-covenant"],
            "system": "You are a COVENANT protocol agent specialized in creating, monitoring, and executing on-chain agreements.",
        }

    async def send_message(self, agent_id: str, message: str, user_id: str = "covenant-protocol") -> Dict[str, Any]:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.eliza_url}/agents/{agent_id}/message",
                json={"text": message, "userId": user_id},
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                return await resp.json()

    async def deploy_agent(self, agent_id: str, wallet: str) -> Dict[str, Any]:
        character = await self.create_character_config(agent_id, wallet)
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.eliza_url}/agents",
                json={"character": character},
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                return await resp.json()

    async def get_agent_status(self, agent_id: str) -> Dict[str, Any]:
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{self.eliza_url}/agents/{agent_id}",
                timeout=aiohttp.ClientTimeout(total=10),
            ) as resp:
                return await resp.json()
