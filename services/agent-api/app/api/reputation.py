from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()


class ReputationLinkRequest(BaseModel):
    platform: str
    external_id: str


class ReputationScoreResponse(BaseModel):
    agent_id: str
    score: float
    sources: List[dict]
    updated_at: Optional[str]


@router.post("/{agent_id}/link-external")
async def link_external_identity(
    agent_id: str,
    req: ReputationLinkRequest,
    request: Request,
):
    registry = request.app.state.registry
    agent = registry.get(agent_id)
    if not agent:
        return {"error": "Agent not found"}, 404

    external_ids = agent.get("external_ids", {})
    external_ids[req.platform] = req.external_id
    registry.update(agent_id, {"external_ids": external_ids})

    return {
        "agent_id": agent_id,
        "platform": req.platform,
        "external_id": req.external_id,
        "status": "linked",
    }


@router.get("/{agent_id}", response_model=ReputationScoreResponse)
async def get_reputation(agent_id: str, request: Request):
    registry = request.app.state.registry
    agent = registry.get(agent_id)
    if not agent:
        return {"error": "Agent not found"}, 404

    # Placeholder: integrate with on-chain ReputationAggregator
    score = agent.get("success_rate", 0.5) * 100
    sources = [
        {"platform": "internal", "score": score, "weight": 1.0},
    ]

    return ReputationScoreResponse(
        agent_id=agent_id,
        score=score,
        sources=sources,
        updated_at=None,
    )
