import asyncio
import json
import os
import sqlite3
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from core.blockchain import check_agent_exists_on_chain
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
            "context": self.context,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "result": self.result,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "CoordinationSession":
        session = CoordinationSession(
            id=data["id"],
            name=data["name"],
            description=data["description"],
            objective=data["objective"],
            context=data.get("context", {}),
        )
        session.status = data.get("status", "created")
        session.agents = json.loads(data["agents"]) if isinstance(data["agents"], str) else data.get("agents", [])
        session.created_at = datetime.fromisoformat(data["created_at"]) if data.get("created_at") else datetime.utcnow()
        session.updated_at = datetime.fromisoformat(data["updated_at"]) if data.get("updated_at") else datetime.utcnow()
        session.completed_at = datetime.fromisoformat(data["completed_at"]) if data.get("completed_at") else None
        session.result = json.loads(data["result"]) if isinstance(data.get("result"), str) else data.get("result")
        return session


class _SessionStore:
    def __init__(self, db_path: str):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._init_db()

    def _init_db(self) -> None:
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    objective TEXT,
                    status TEXT,
                    agents TEXT,
                    context TEXT,
                    created_at TEXT,
                    updated_at TEXT,
                    completed_at TEXT,
                    result TEXT
                )
                """
            )
            conn.commit()

    def insert(self, session: CoordinationSession) -> None:
        data = session.to_dict()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """
                INSERT INTO sessions
                (id, name, description, objective, status, agents, context,
                 created_at, updated_at, completed_at, result)
                VALUES
                (:id, :name, :description, :objective, :status, :agents, :context,
                 :created_at, :updated_at, :completed_at, :result)
                """,
                {
                    **data,
                    "agents": json.dumps(data["agents"]),
                    "context": json.dumps(data["context"]),
                    "result": json.dumps(data["result"]) if data["result"] is not None else None,
                },
            )
            conn.commit()

    def update(self, session: CoordinationSession) -> None:
        data = session.to_dict()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                """
                UPDATE sessions SET
                    name = :name,
                    description = :description,
                    objective = :objective,
                    status = :status,
                    agents = :agents,
                    context = :context,
                    created_at = :created_at,
                    updated_at = :updated_at,
                    completed_at = :completed_at,
                    result = :result
                WHERE id = :id
                """,
                {
                    **data,
                    "agents": json.dumps(data["agents"]),
                    "context": json.dumps(data["context"]),
                    "result": json.dumps(data["result"]) if data["result"] is not None else None,
                },
            )
            conn.commit()

    def get(self, session_id: str) -> Optional[CoordinationSession]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                "SELECT * FROM sessions WHERE id = ?", (session_id,)
            ).fetchone()
            if not row:
                return None
            data = dict(row)
            data["agents"] = json.loads(data["agents"]) if data.get("agents") else []
            data["context"] = json.loads(data["context"]) if data.get("context") else {}
            data["result"] = json.loads(data["result"]) if data.get("result") else None
            return CoordinationSession.from_dict(data)

    def list(self, status: Optional[str] = None) -> List[CoordinationSession]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            if status:
                rows = conn.execute(
                    "SELECT * FROM sessions WHERE status = ?", (status,)
                ).fetchall()
            else:
                rows = conn.execute("SELECT * FROM sessions").fetchall()
            sessions = []
            for row in rows:
                data = dict(row)
                data["agents"] = json.loads(data["agents"]) if data.get("agents") else []
                data["context"] = json.loads(data["context"]) if data.get("context") else {}
                data["result"] = json.loads(data["result"]) if data.get("result") else None
                sessions.append(CoordinationSession.from_dict(data))
            return sessions


class AgentCoordinator:
    def __init__(self, registry: AgentRegistry):
        self.registry = registry
        self._store = _SessionStore(os.path.expanduser("~/.covenant/sessions/sessions.db"))
        self._tasks = TaskQueue()

    def _verify_agent_on_chain(self, agent_id: str, agent: Dict[str, Any]) -> None:
        wallet = agent.get("wallet_address")
        if not wallet:
            raise ValueError(f"Agent {agent_id} has no wallet_address")
        if not check_agent_exists_on_chain(wallet):
            raise ValueError(f"Agent {agent_id} is not registered on-chain")

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
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(
                None, self._verify_agent_on_chain, agent_id, agent
            )
            session.agents.append({"agent_id": agent_id, "role": "participant", "status": "idle"})

        await asyncio.get_event_loop().run_in_executor(None, self._store.insert, session)
        return session.to_dict()

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        session = self._store.get(session_id)
        return session.to_dict() if session else None

    def list_sessions(self, status: str = None) -> List[Dict[str, Any]]:
        sessions = self._store.list(status=status)
        return [s.to_dict() for s in sessions]

    async def add_agent(self, session_id: str, agent_id: str, role: str = "participant") -> Optional[Dict[str, Any]]:
        session = self._store.get(session_id)
        if not session:
            return None
        agent = self.registry.get(agent_id)
        if not agent:
            raise ValueError(f"Agent {agent_id} not found")
        await asyncio.get_event_loop().run_in_executor(
            None, self._verify_agent_on_chain, agent_id, agent
        )
        session.agents.append({"agent_id": agent_id, "role": role, "status": "idle"})
        session.updated_at = datetime.utcnow()
        await asyncio.get_event_loop().run_in_executor(None, self._store.update, session)
        return session.to_dict()

    async def remove_agent(self, session_id: str, agent_id: str) -> Optional[Dict[str, Any]]:
        session = self._store.get(session_id)
        if not session:
            return None
        session.agents = [a for a in session.agents if a["agent_id"] != agent_id]
        session.updated_at = datetime.utcnow()
        await asyncio.get_event_loop().run_in_executor(None, self._store.update, session)
        return session.to_dict()

    async def execute_session(self, session_id: str) -> Dict[str, Any]:
        session = self._store.get(session_id)
        if not session:
            raise ValueError("Session not found")

        session.status = "running"
        session.updated_at = datetime.utcnow()
        await asyncio.get_event_loop().run_in_executor(None, self._store.update, session)

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
        await asyncio.get_event_loop().run_in_executor(None, self._store.update, session)

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
        session = self._store.get(session_id)
        if not session:
            return False
        session.status = "cancelled"
        session.updated_at = datetime.utcnow()
        await asyncio.get_event_loop().run_in_executor(None, self._store.update, session)
        return True
