import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional


class AgentTask:
    def __init__(
        self,
        id: str,
        task_type: str,
        payload: Dict[str, Any],
        priority: int,
        agent_id: Optional[str],
    ):
        self.id = id
        self.task_type = task_type
        self.payload = payload
        self.priority = priority
        self.agent_id = agent_id
        self.status = "pending"
        self.result = None
        self.error = None
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.started_at = None
        self.completed_at = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "task_type": self.task_type,
            "payload": self.payload,
            "priority": self.priority,
            "agent_id": self.agent_id,
            "status": self.status,
            "result": self.result,
            "error": self.error,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
        }


class TaskQueue:
    def __init__(self):
        self._tasks: Dict[str, AgentTask] = {}

    def enqueue(
        self,
        task_type: str,
        payload: Dict[str, Any],
        priority: int = 1,
        agent_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        task_id = str(uuid.uuid4())
        task = AgentTask(task_id, task_type, payload, priority, agent_id)
        self._tasks[task_id] = task
        return task.to_dict()

    def get(self, task_id: str) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        return task.to_dict() if task else None

    def list_tasks(self, status: str = None, agent_id: str = None) -> List[Dict[str, Any]]:
        tasks = self._tasks.values()
        if status:
            tasks = [t for t in tasks if t.status == status]
        if agent_id:
            tasks = [t for t in tasks if t.agent_id == agent_id]
        return [t.to_dict() for t in tasks]

    def cancel(self, task_id: str) -> bool:
        task = self._tasks.get(task_id)
        if not task or task.status in ("completed", "failed"):
            return False
        task.status = "cancelled"
        task.updated_at = datetime.utcnow()
        return True

    def retry(self, task_id: str) -> Dict[str, Any]:
        task = self._tasks.get(task_id)
        if not task:
            raise ValueError("Task not found")
        if task.status not in ("failed", "cancelled"):
            raise ValueError("Only failed or cancelled tasks can be retried")
        task.status = "pending"
        task.error = None
        task.result = None
        task.updated_at = datetime.utcnow()
        return task.to_dict()

    def assign(self, task_id: str, agent_id: str) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        if not task:
            return None
        task.agent_id = agent_id
        task.status = "assigned"
        task.updated_at = datetime.utcnow()
        return task.to_dict()

    def start(self, task_id: str) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        if not task:
            return None
        task.status = "running"
        task.started_at = datetime.utcnow()
        task.updated_at = datetime.utcnow()
        return task.to_dict()

    def complete(self, task_id: str, result: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        if not task:
            return None
        task.status = "completed"
        task.result = result
        task.completed_at = datetime.utcnow()
        task.updated_at = datetime.utcnow()
        return task.to_dict()

    def fail(self, task_id: str, error: str) -> Optional[Dict[str, Any]]:
        task = self._tasks.get(task_id)
        if not task:
            return None
        task.status = "failed"
        task.error = error
        task.updated_at = datetime.utcnow()
        return task.to_dict()
