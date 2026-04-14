from fastapi import APIRouter, Depends, Request, HTTPException
from pydantic import BaseModel
from typing import Any, Dict, Optional

router = APIRouter()


class ExecutionRequest(BaseModel):
    covenant_address: str
    condition_id: str
    proof_hash: Optional[str] = None
    executor_agent_id: Optional[str] = None


class ExecutionResponse(BaseModel):
    covenant_address: str
    status: str
    executor: Optional[str]
    tx_hash: Optional[str]


@router.post("/intent")
async def submit_execution_intent(req: ExecutionRequest, request: Request):
    """Submit an intent to autonomously execute a covenant condition."""
    registry = request.app.state.registry
    engine = request.app.state.execution_engine

    executor_id = req.executor_agent_id
    if executor_id:
        agent = registry.get(executor_id)
        if not agent:
            raise HTTPException(status_code=404, detail="Executor agent not found")

    try:
        result = await engine.submit_intent(
            covenant_address=req.covenant_address,
            condition_id=req.condition_id,
            executor_agent_id=executor_id,
            proof_hash=req.proof_hash,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Blockchain submission failed: {exc}")

    return ExecutionResponse(
        covenant_address=req.covenant_address,
        status=result.get("status", "submitted"),
        executor=executor_id,
        tx_hash=result.get("tx_hash"),
    )


@router.post("/verify")
async def verify_execution(req: ExecutionRequest, request: Request):
    """Verify an autonomous execution and release reward."""
    engine = request.app.state.execution_engine

    try:
        result = await engine.verify_intent_by_covenant(
            covenant_address=req.covenant_address,
            proof_hash=req.proof_hash,
            validation_data="",
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Blockchain verification failed: {exc}")

    return ExecutionResponse(
        covenant_address=req.covenant_address,
        status=result.get("status", "verified"),
        executor=req.executor_agent_id,
        tx_hash=result.get("tx_hash"),
    )
