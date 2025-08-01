from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    app_name: str = "Simple FastAPI App"
    app_version: str = "1.0.0"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    
    # 데이터베이스 설정
    database_url: str = "mysql+pymysql://root:1234@localhost:3306/surine_db?charset=utf8mb4"

# 설정 인스턴스 생성
settings = Settings()
