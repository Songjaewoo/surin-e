from typing import Optional, AnyStr

from fastapi import FastAPI, Request, Depends, HTTPException, status, Body
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm.session import Session
from starlette.middleware.sessions import SessionMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext

from crud import crud
from dependencies import create_access_token, get_current_user
from models.db_models import UserModel
from routers import place, bookmark, record, user
from db.database import engine, get_db
from models import db_models
import uvicorn
from schemas.models import User, UserCreate, APIResponse, Token, TokenData, UserLoginResponse
from config import settings

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
app.include_router(place.router)
app.include_router(bookmark.router)
app.include_router(record.router)
app.include_router(user.router)

app.add_middleware(SessionMiddleware, secret_key=settings.SECRET_KEY)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
