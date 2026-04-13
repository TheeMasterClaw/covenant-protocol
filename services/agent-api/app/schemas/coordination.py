from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class CoordinationCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(default=None, max_length=5000)
    objective: str = Field(..., min_length=1, max_length=5000)
    agent_ids: List[str] = Field(..., min_length=1)
    context: Dict[str, Any] = Field(default_factory=dict)


class CoordinationResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    objective: str
    status: str
    agents: List[Dict[str, Any]]
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    result: Optional[Dict[str, Any]]

    class Config:
        from_attributes = True


class CoordinationResult(BaseModel):
    session_id: str
    status: str
    result: Dict[str, Any]
    completed_at: datetime
    agent_results: List[Dict[str, Any]]


class AgentAssignment(BaseModel):
    agent_id: str
    role: str = "participant"
