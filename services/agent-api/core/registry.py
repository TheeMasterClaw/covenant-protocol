import uuid
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional


class AgentType(str, Enum):
    COVENANT = "covenant"
    TASK = "task"
    DISPUTE = "dispute"
    REPUTATION = "reputation"
    GOVERNANCE = "governance"
    CUSTOM = "custom"


class Agent:
    def __init__(
        self,
        id: str,
        name: str,
        agent_type: AgentType,
        description: str,
        capabilities: List[str],
        config: Dict[str, Any],
        owner: str,
    ):
        self.id = id
        self.name = name
        self.agent_type = agent_type
        self.description = description
        self.capabilities = capabilities or []
        self.config = config or {}
        self.owner = owner.lower()
        self.active = True
        self.status = "idle"
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.last_heartbeat = None
        self.total_tasks = 0
        self.successful_tasks = 0
        self.external_ids: Dict[str, str] = {}  # platform -> external_id
        self.wallet_address: Optional[str] = None
        self.reputation_score: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "agent_type": self.agent_type.value,
            "description": self.description,
            "capabilities": self.capabilities,
            "config": self.config,
            "owner": self.owner,
            "active": self.active,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "last_heartbeat": self.last_heartbeat.isoformat() if self.last_heartbeat else None,
            "total_tasks": self.total_tasks,
            "success_rate": self.successful_tasks / max(self.total_tasks, 1),
            "external_ids": self.external_ids,
            "wallet_address": self.wallet_address,
            "reputation_score": self.reputation_score,
        }


class AgentRegistry:
    def __init__(self):
        self._agents: Dict[str, Agent] = {}

    def register(
        self,
        name: str,
        agent_type: AgentType,
        description: str = "",
        capabilities: List[str] = None,
        config: Dict[str, Any] = None,
        owner: str = "",
    ) -> Dict[str, Any]:
        agent_id = str(uuid.uuid4())
        agent = Agent(
            id=agent_id,
            name=name,
            agent_type=agent_type,
            description=description,
            capabilities=capabilities or [],
            config=config or {},
            owner=owner,
        )
        self._agents[agent_id] = agent
        return agent.to_dict()

    def get(self, agent_id: str) -> Optional[Dict[str, Any]]:
        agent = self._agents.get(agent_id)
        return agent.to_dict() if agent else None

    def list_agents(self, active_only: bool = True) -> List[Dict[str, Any]]:
        agents = self._agents.values()
        if active_only:
            agents = [a for a in agents if a.active]
        return [a.to_dict() for a in agents]

    def update(self, agent_id: str, fields: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        agent = self._agents.get(agent_id)
        if not agent:
            return None
        for key, value in fields.items():
            if hasattr(agent, key):
                setattr(agent, key, value)
        agent.updated_at = datetime.utcnow()
        return agent.to_dict()

    def unregister(self, agent_id: str) -> bool:
        if agent_id in self._agents:
            del self._agents[agent_id]
            return True
        return False

    def activate(self, agent_id: str) -> Optional[Dict[str, Any]]:
        return self.update(agent_id, {"active": True})

    def deactivate(self, agent_id: str) -> Optional[Dict[str, Any]]:
        return self.update(agent_id, {"active": False})

    def find_by_capabilities(self, capabilities: List[str]) -> List[Dict[str, Any]]:
        results = []
        for agent in self._agents.values():
            if not agent.active:
                continue
            if any(cap in agent.capabilities for cap in capabilities):
                results.append(agent.to_dict())
        return results

    def find_by_external_id(self, platform: str, external_id: str) -> Optional[Dict[str, Any]]:
        for agent in self._agents.values():
            if agent.external_ids.get(platform) == external_id:
                return agent.to_dict()
        return None
