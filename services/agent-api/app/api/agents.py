from typing import List
from fastapi import APIRouter, HTTPException, Request, status

from app.schemas.agent import AgentCreate, AgentResponse, AgentUpdate, AgentExecute
from core.registry import AgentType

router = APIRouter()


@router.get("", response_model=List[AgentResponse])
async def list_agents(request: Request, active_only: bool = True):
    registry = request.app.state.registry
    agents = registry.list_agents(active_only=active_only)
    return agents


@router.post("", response_model=AgentResponse, status_code=status.HTTP_201_CREATED)
async def register_agent(request: Request, agent_in: AgentCreate):
    registry = request.app.state.registry
    try:
        agent = registry.register(
            name=agent_in.name,
            agent_type=AgentType(agent_in.agent_type),
            description=agent_in.description,
            capabilities=agent_in.capabilities,
            config=agent_in.config,
            owner=agent_in.owner,
        )
        return agent
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{agent_id}", response_model=AgentResponse)
async def get_agent(request: Request, agent_id: str):
    registry = request.app.state.registry
    agent = registry.get(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    return agent


@router.patch("/{agent_id}", response_model=AgentResponse)
async def update_agent(request: Request, agent_id: str, agent_in: AgentUpdate):
    registry = request.app.state.registry
    agent = registry.update(agent_id, agent_in.model_dump(exclude_unset=True))
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    return agent


@router.delete("/{agent_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_agent(request: Request, agent_id: str):
    registry = request.app.state.registry
    success = registry.unregister(agent_id)
    if not success:
        raise HTTPException(status_code=404, detail="Agent not found")
    return None


@router.post("/{agent_id}/execute")
async def execute_agent(request: Request, agent_id: str, execution: AgentExecute):
    coordinator = request.app.state.coordinator
    try:
        result = await coordinator.execute_single(agent_id, execution.task, execution.context)
        return {"agent_id": agent_id, "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{agent_id}/activate")
async def activate_agent(request: Request, agent_id: str):
    registry = request.app.state.registry
    agent = registry.activate(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    return agent


@router.post("/{agent_id}/deactivate")
async def deactivate_agent(request: Request, agent_id: str):
    registry = request.app.state.registry
    agent = registry.deactivate(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    return agent
