from pathlib import Path

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_ENV_FILE = _PROJECT_ROOT / ".env"
_RELATIVE_SQLITE_PREFIX = "sqlite+aiosqlite:///./"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=_ENV_FILE, env_file_encoding="utf-8", extra="ignore")

    database_url: str = "sqlite+aiosqlite:///./tilahan_saathi.db"

    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30  # 30 days (no refresh-token flow, see auth router)

    firebase_credentials_path: str = "secrets/firebase-service-account.json"

    llm_model: str = "ollama_chat/gemma4"
    llm_temperature: float = 0.2
    llm_timeout_seconds: int = 90  # local Ollama models can take ~60s; cloud providers are much faster

    agmarknet_api_url: str = "https://api.agmarknet.gov.in/v1/dashboard-data/"
    agmarknet_timeout_seconds: int = 10

    @model_validator(mode="after")
    def _resolve_relative_sqlite_path(self) -> "Settings":
        # A relative sqlite path (the default, and what .env ships with) resolves
        # against the process's cwd, not the project root — breaks any script or
        # tool invoked from outside api/. Anchor it to the project root instead.
        if self.database_url.startswith(_RELATIVE_SQLITE_PREFIX):
            relative_path = self.database_url.removeprefix(_RELATIVE_SQLITE_PREFIX)
            absolute_path = _PROJECT_ROOT / relative_path
            self.database_url = f"sqlite+aiosqlite:///{absolute_path}"
        return self


settings = Settings()
