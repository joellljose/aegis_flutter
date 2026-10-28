from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AEGIS One Authentication & Access Control API"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173,http://127.0.0.1:3000,*"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = ""
    FIREBASE_PROJECT_ID: str = "aegis-one-dev"
    FIRESTORE_EMULATOR_HOST: str = ""
    FIREBASE_AUTH_EMULATOR_HOST: str = ""

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Administrative Bootstrap
    ADMIN_BOOTSTRAP_SECRET: str = "aegis-secure-bootstrap-dev-secret-key-9821"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origins_list(self) -> List[str]:
        if not self.CORS_ORIGINS:
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


settings = Settings()
