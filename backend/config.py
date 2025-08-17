from typing import ClassVar

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Simple FastAPI App"
    app_version: str = "1.0.0"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    
    # 데이터베이스 설정
    database_url: str

    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    NAVER_SEARCH_API_CLIENT_ID: str
    NAVER_SEARCH_API_CLIENT_SECRET: str

    class Config:
        env_file = ".env"


# 설정 인스턴스 생성
settings = Settings()
