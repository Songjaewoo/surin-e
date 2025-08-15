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
from routers import place, bookmark, record
from db.database import engine, get_db
from models import db_models
import uvicorn
from schemas.models import User, UserCreate, APIResponse, Token, TokenData, UserLoginResponse

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

app.add_middleware(SessionMiddleware, secret_key="super-secret-key")

ACCESS_TOKEN_EXPIRE_MINUTES = 30
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@app.post("/register", response_model=APIResponse)
def register_user(user: UserCreate,
                  db: Session = Depends(get_db)):

    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="email already registered")

    db_user = crud.create_user(db=db, user=user)
    return {"data": {"user_id" : db_user.id},
            "success": True,
            "message": "User created successfully"}

@app.post("/token", response_model=Token)
async def login_for_access_token(email: str = Body(..., description="사용자 이메일"),
                                 password: str = Body(..., description="사용자 비밀번호"),
                                 db: Session = Depends(get_db)):

    user = crud.get_user_by_email(db, email=email)
    if not user or not pwd_context.verify(password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect nickname or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    print('user.id', user.id)
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/me", response_model=UserLoginResponse)
async def read_users_me(current_user: UserModel = Depends(get_current_user)):
    return current_user

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
