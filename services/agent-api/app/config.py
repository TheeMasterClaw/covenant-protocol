from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "COVENANT Agent API"
    DEBUG: bool = False
    LOG_LEVEL: str = "info"

    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost/covenant_agents"
    REDIS_URL: str = "redis://localhost:6379"

    CORS_ORIGINS: List[str] = ["*"]

    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""

    WEB3_RPC_URL: str = ""
    CHAIN_ID: int = 1

    SENTRY_DSN: str = ""

    CELERY_BROKER_URL: str = ""
    CELERY_RESULT_BACKEND: str = ""

    AGENT_EXECUTION_TIMEOUT: int = 300
    MAX_CONCURRENT_AGENTS: int = 100

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
