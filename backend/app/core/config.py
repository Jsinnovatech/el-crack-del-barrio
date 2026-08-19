from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql://usuario:password@localhost:5432/vitrina_deportiva"
    jwt_secret: str = "cambia-este-valor"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080  # 7 días
    otp_dev_code: str = "123456"
    cors_origins: str = "http://localhost:3000"
    uploads_dir: str = "./uploads"
    env: str = "development"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    def model_post_init(self, __context) -> None:
        # Strip espacios por si el env var viene con espacios extra
        object.__setattr__(self, 'otp_dev_code', self.otp_dev_code.strip())

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()
