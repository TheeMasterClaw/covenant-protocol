from datetime import datetime
from typing import Any, Dict, Optional
from enum import Enum
from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TaskCreate(BaseModel):
    task_type: str = Field(..., min_length=1, max_length=100)
    payload: Dict[str, Any] = Field(default_factory=dict)
    priority: int = Field(default=1, ge=1, le=10)
    preferred_agent: Optional[str] = None


class TaskResponse(BaseModel):
    id: str
    task_type: str
    payload: Dict[str, Any]
    priority: int
    status: TaskStatus
    agent_id: Optional[str]
    result: Optional[Dict[str, Any]]
    error: Optional[str]
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]

    class Config:
        from_attributes = True
