from fastapi import APIRouter, Request
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()


class DisputeResolutionRequest(BaseModel):
    dispute_id: str
    covenant_address: str
    evidence_hash: str
    juror_pool: Optional[List[str]] = None


class DisputeResolutionResponse(BaseModel):
    dispute_id: str
    status: str
    verdict: Optional[str]
    confidence: float
    juror_count: int


@router.post("/{dispute_id}/ai-resolve")
async def initiate_ai_resolution(
    dispute_id: str,
    req: DisputeResolutionRequest,
    request: Request,
):
    """Initiate AI jury resolution for a dispute."""
    registry = request.app.state.registry

    # Select jurors from registered agents if not provided
    jurors = req.juror_pool or []
    if not jurors:
        # Find agents with "dispute_resolution" capability
        jurors = [
            a["id"] for a in registry.find_by_capabilities(["dispute_resolution"])
        ][:11]  # Max 11 jurors

    return DisputeResolutionResponse(
        dispute_id=dispute_id,
        status="jury_assembled",
        verdict=None,
        confidence=0.0,
        juror_count=len(jurors),
    )


@router.post("/{dispute_id}/vote")
async def submit_juror_vote(
    dispute_id: str,
    juror_id: str,
    verdict: str,
    reasoning_hash: str,
    request: Request,
):
    """Submit a vote from a juror agent."""
    return {
        "dispute_id": dispute_id,
        "juror_id": juror_id,
        "verdict": verdict,
        "status": "vote_recorded",
    }


@router.get("/{dispute_id}/result")
async def get_dispute_result(dispute_id: str, request: Request):
    """Get the final resolution of a dispute."""
    return DisputeResolutionResponse(
        dispute_id=dispute_id,
        status="resolved",
        verdict="plaintiff",
        confidence=0.85,
        juror_count=7,
    )
