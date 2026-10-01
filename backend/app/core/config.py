from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str = "postgresql+asyncpg://caloai:caloai@localhost:5432/caloai"
    jwt_secret: str = Field(min_length=32)
    google_client_id: str = Field(min_length=1)
    groq_api_key: str = ""
    groq_model: str = "qwen/qwen3.8-27b"
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.1-flash-lite"
    food_recognition_provider: str = "groq"
    max_upload_bytes: int = 10 * 1024 * 1024
    allowed_origins: str = ""
    access_token_minutes: int = 15
    refresh_token_days: int = 30

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
