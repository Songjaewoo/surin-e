from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import items, users
from db.database import engine
from models import db_models
import uvicorn

# 데이터베이스 테이블 생성
db_models.Base.metadata.create_all(bind=engine)

# FastAPI 앱 인스턴스 생성
app = FastAPI(
    title="Simple FastAPI App with Database",
    description="SQLAlchemy와 SQLite를 사용한 FastAPI 예제 애플리케이션",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS 미들웨어 추가
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(items.router)
app.include_router(users.router)

@app.get("/")
async def root():
    return {
        "message": "hello"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
