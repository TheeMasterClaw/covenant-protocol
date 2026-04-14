import json
from typing import Any, Dict, List

import aiohttp


class FetchAdapter:
    """Bridge to Fetch.ai uAgents and Almanac."""

    def __init__(
        self,
        almanac_url: str = "https://agentverse.ai/v1/agents",
        agentverse_url: str = "https://agentverse.ai",
    ):
        self.almanac_url = almanac_url
        self.agentverse_url = agentverse_url.rstrip("/")

    async def discover_agents(self, protocol: str, capability: str = "") -> List[Dict[str, Any]]:
        params = {"protocol": protocol}
        if capability:
            params["capability"] = capability
        async with aiohttp.ClientSession() as session:
            async with session.get(
                self.almanac_url,
                params=params,
                timeout=aiohttp.ClientTimeout(total=15),
            ) as resp:
                data = await resp.json()
                return data.get("agents", [])

    async def send_to_agent(self, agent_address: str, message: Dict[str, Any]) -> Dict[str, Any]:
        """Send a message to a uAgent via Agentverse proxy or direct endpoint."""
        payload = {
            "recipient": agent_address,
            "payload": json.dumps(message),
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.agentverse_url}/proxy/submit",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                return await resp.json()

    async def deploy_uagent(self, name: str, seed: str, code: str) -> Dict[str, Any]:
        """Deploy a uAgent to Agentverse (requires API key in practice)."""
        payload = {
            "name": name,
            "seed": seed,
            "code": code,
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.agentverse_url}/v1/agents",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=60),
            ) as resp:
                return await resp.json()
