from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "sqlite+aiosqlite:///./tilahan_saathi.db"

    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30  # 30 days (no refresh-token flow, see auth router)

    firebase_credentials_path: str = "secrets/firebase-service-account.json"

    llm_model: str = "ollama_chat/gemma4"
    llm_temperature: float = 0.2
    llm_timeout_seconds: int = 90  # local Ollama models can take ~60s; cloud providers are much faster


settings = Settings()
