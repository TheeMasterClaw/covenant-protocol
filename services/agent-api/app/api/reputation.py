from fastapi import APIRouter, Depends, Request, HTTPException
from pydantic import BaseModel
from typing import List, Optional

from core.blockchain import get_on_chain_reputation

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
        raise HTTPException(status_code=404, detail="Agent not found")

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
        raise HTTPException(status_code=404, detail="Agent not found")

    wallet = agent.get("wallet_address")
    if not wallet:
        raise HTTPException(status_code=400, detail="Agent has no wallet_address")

    try:
        rep = get_on_chain_reputation(wallet)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Reputation read failed: {exc}")

    return ReputationScoreResponse(
        agent_id=agent_id,
        score=rep["score"],
        sources=rep["sources"],
        updated_at=None,
    )
