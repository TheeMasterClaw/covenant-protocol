from typing import List
from fastapi import APIRouter, HTTPException, Request, status

from app.schemas.coordination import (
    CoordinationCreate,
    CoordinationResponse,
    CoordinationResult,
    AgentAssignment,
)

router = APIRouter()


@router.get("", response_model=List[CoordinationResponse])
async def list_coordinations(request: Request, status_filter: str = None):
    coordinator = request.app.state.coordinator
    sessions = coordinator.list_sessions(status=status_filter)
    return sessions


@router.post("", response_model=CoordinationResponse, status_code=status.HTTP_201_CREATED)
async def create_coordination(request: Request, coord_in: CoordinationCreate):
    coordinator = request.app.state.coordinator
    try:
        session = await coordinator.create_session(
            name=coord_in.name,
            description=coord_in.description,
            objective=coord_in.objective,
            agent_ids=coord_in.agent_ids,
            context=coord_in.context,
        )
        return session
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{session_id}", response_model=CoordinationResponse)
async def get_coordination(request: Request, session_id: str):
    coordinator = request.app.state.coordinator
    session = coordinator.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Coordination session not found")
    return session


@router.post("/{session_id}/start", response_model=CoordinationResult)
async def start_coordination(request: Request, session_id: str):
    coordinator = request.app.state.coordinator
    try:
        result = await coordinator.execute_session(session_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{session_id}/agents", response_model=CoordinationResponse)
async def add_agent_to_coordination(
    request: Request, session_id: str, assignment: AgentAssignment
):
    coordinator = request.app.state.coordinator
    session = coordinator.add_agent(session_id, assignment.agent_id, assignment.role)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@router.delete("/{session_id}/agents/{agent_id}", response_model=CoordinationResponse)
async def remove_agent_from_coordination(request: Request, session_id: str, agent_id: str):
    coordinator = request.app.state.coordinator
    session = coordinator.remove_agent(session_id, agent_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@router.post("/{session_id}/cancel")
async def cancel_coordination(request: Request, session_id: str):
    coordinator = request.app.state.coordinator
    success = await coordinator.cancel_session(session_id)
    if not success:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"status": "cancelled"}
