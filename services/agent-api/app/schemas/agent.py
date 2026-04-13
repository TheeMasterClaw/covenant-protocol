from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class AgentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    agent_type: str
    description: Optional[str] = Field(default=None, max_length=5000)
    capabilities: List[str] = Field(default_factory=list)
    config: Dict[str, Any] = Field(default_factory=dict)
    owner: str = Field(..., pattern=r"^0x[a-fA-F0-9]{40}$")


class AgentCreate(AgentBase):
    pass


class AgentUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=5000)
    capabilities: Optional[List[str]] = None
    config: Optional[Dict[str, Any]] = None
    active: Optional[bool] = None


class AgentResponse(AgentBase):
    id: str
    active: bool
    status: str
    created_at: datetime
    updated_at: datetime
    last_heartbeat: Optional[datetime] = None
    total_tasks: int = 0
    success_rate: float = 0.0

    class Config:
        from_attributes = True


class AgentExecute(BaseModel):
    task: str = Field(..., min_length=1, max_length=10000)
    context: Dict[str, Any] = Field(default_factory=dict)
