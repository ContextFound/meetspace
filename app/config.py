from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    database_url: str = "postgresql+asyncpg://user:password@localhost:5432/meetspace"
    environment: str = "development"
    api_key_prefix: str = "ms_test_"
    cors_origins: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ]
    cors_origins_dev: List[str] = ["*"]

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"

    @property
    def effective_cors_origins(self) -> List[str]:
        if self.is_production:
            return self.cors_origins
        return self.cors_origins_dev


settings = Settings()
