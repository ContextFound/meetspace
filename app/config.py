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

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


settings = Settings()
