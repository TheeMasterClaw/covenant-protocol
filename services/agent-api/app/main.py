import sentry_sdk
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.api import agents, coordination, health, tasks
from core.registry import AgentRegistry
from core.coordinator import AgentCoordinator
from core.database import init_db

if settings.SENTRY_DSN:
    sentry_sdk.init(dsn=settings.SENTRY_DSN, traces_sample_rate=0.1)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    app.state.registry = AgentRegistry()
    app.state.coordinator = AgentCoordinator(app.state.registry)
    yield


app = FastAPI(
    title="COVENANT Agent API",
    description="AI Agent Orchestrator for COVENANT Protocol",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, tags=["health"])
app.include_router(agents.router, prefix="/agents", tags=["agents"])
app.include_router(coordination.router, prefix="/coordinations", tags=["coordination"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])


@app.get("/")
async def root():
    return {
        "name": "COVENANT Agent API",
        "version": "1.0.0",
        "docs": "/docs",
    }
