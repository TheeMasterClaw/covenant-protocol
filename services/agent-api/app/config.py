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
    COVENANT_RPC_URL: str = "https://testrpc.xlayer.tech"
    CHAIN_ID: int = 1

    AGENT_REGISTRY_ADDRESS: str = ""
    COVENANT_FACTORY_ADDRESS: str = ""
    TASK_MARKET_ADDRESS: str = ""
    REPUTATION_STAKE_ADDRESS: str = ""
    REPUTATION_AGGREGATOR_ADDRESS: str = ""
    AUTONOMOUS_EXECUTOR_ADDRESS: str = ""

    EXECUTOR_PRIVATE_KEY: str = ""

    SENTRY_DSN: str = ""

    CELERY_BROKER_URL: str = ""
    CELERY_RESULT_BACKEND: str = ""

    AGENT_EXECUTION_TIMEOUT: int = 300
    MAX_CONCURRENT_AGENTS: int = 100

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
