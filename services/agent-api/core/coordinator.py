import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from core.registry import AgentRegistry
from core.tasks import TaskQueue, AgentTask


class CoordinationSession:
    def __init__(self, id: str, name: str, description: str, objective: str, context: Dict[str, Any]):
        self.id = id
        self.name = name
        self.description = description
        self.objective = objective
        self.status = "created"
        self.agents: List[Dict[str, Any]] = []
        self.context = context
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.completed_at = None
        self.result = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "objective": self.objective,
            "status": self.status,
            "agents": self.agents,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "result": self.result,
        }


class AgentCoordinator:
    def __init__(self, registry: AgentRegistry):
        self.registry = registry
        self._sessions: Dict[str, CoordinationSession] = {}
        self._tasks = TaskQueue()

    async def create_session(
        self,
        name: str,
        description: str,
        objective: str,
        agent_ids: List[str],
        context: Dict[str, Any],
    ) -> Dict[str, Any]:
        session_id = str(uuid.uuid4())
        session = CoordinationSession(session_id, name, description, objective, context)

        for agent_id in agent_ids:
            agent = self.registry.get(agent_id)
            if not agent:
                raise ValueError(f"Agent {agent_id} not found")
            session.agents.append({"agent_id": agent_id, "role": "participant", "status": "idle"})

        self._sessions[session_id] = session
        return session.to_dict()

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        session = self._sessions.get(session_id)
        return session.to_dict() if session else None

    def list_sessions(self, status: str = None) -> List[Dict[str, Any]]:
        sessions = self._sessions.values()
        if status:
            sessions = [s for s in sessions if s.status == status]
        return [s.to_dict() for s in sessions]

    def add_agent(self, session_id: str, agent_id: str, role: str = "participant") -> Optional[Dict[str, Any]]:
        session = self._sessions.get(session_id)
        if not session:
            return None
        agent = self.registry.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        session.agents.append({"agent_id": agent_id, "role": role, "status": "idle"})
        session.updated_at = datetime.utcnow()
        return session.to_dict()

    def remove_agent(self, session_id: str, agent_id: str) -> Optional[Dict[str, Any]]:
        session = self._sessions.get(session_id)
        if not session:
            return None
        session.agents = [a for a in session.agents if a["agent_id"] != agent_id]
        session.updated_at = datetime.utcnow()
        return session.to_dict()

    async def execute_session(self, session_id: str) -> Dict[str, Any]:
        session = self._sessions.get(session_id)
        if not session:
            raise ValueError("Session not found")

        session.status = "running"
        session.updated_at = datetime.utcnow()

        agent_results = []
        for agent_ref in session.agents:
            agent_id = agent_ref["agent_id"]
            result = await self.execute_single(
                agent_id,
                session.objective,
                session.context,
            )
            agent_results.append({"agent_id": agent_id, "result": result})
            agent_ref["status"] = "completed"

        session.status = "completed"
        session.completed_at = datetime.utcnow()
        session.result = {"agent_results": agent_results}

        return {
            "session_id": session_id,
            "status": session.status,
            "result": session.result,
            "completed_at": session.completed_at.isoformat(),
            "agent_results": agent_results,
        }

    async def execute_single(self, agent_id: str, task: str, context: Dict[str, Any]) -> Dict[str, Any]:
        agent = self.registry.get(agent_id)
        if not agent:
            raise ValueError("Agent not found")

        # Placeholder for actual LLM/agent execution
        return {
            "agent_id": agent_id,
            "task": task,
            "context": context,
            "output": f"Executed task by {agent['name']}",
            "timestamp": datetime.utcnow().isoformat(),
        }

    async def assign_task(
        self,
        task_type: str,
        payload: Dict[str, Any],
        priority: int = 1,
        preferred_agent: str = None,
    ) -> Dict[str, Any]:
        return self._tasks.enqueue(
            task_type=task_type,
            payload=payload,
            priority=priority,
            agent_id=preferred_agent,
        )

    def get_task(self, task_id: str) -> Optional[Dict[str, Any]]:
        return self._tasks.get(task_id)

    def get_task_status(self, task_id: str) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        if not task:
            return None
        return {
            "task_id": task_id,
            "status": task["status"],
            "agent_id": task.get("agent_id"),
            "created_at": task["created_at"],
            "updated_at": task["updated_at"],
        }

    def cancel_task(self, task_id: str) -> bool:
        return self._tasks.cancel(task_id)

    def retry_task(self, task_id: str) -> Dict[str, Any]:
        return self._tasks.retry(task_id)

    async def cancel_session(self, session_id: str) -> bool:
        session = self._sessions.get(session_id)
        if not session:
            return False
        session.status = "cancelled"
        session.updated_at = datetime.utcnow()
        return True
