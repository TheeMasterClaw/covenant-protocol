from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from core.database import get_session

router = APIRouter()


@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "agent-api"}


@router.get("/ready")
async def readiness_check(session: AsyncSession = Depends(get_session)):
    try:
        await session.execute(text("SELECT 1"))
        return {"ready": True}
    except Exception as e:
        return {"ready": False, "error": str(e)}
