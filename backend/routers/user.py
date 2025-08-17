from fastapi import APIRouter, HTTPException, Depends, Query, FastAPI
from sqlalchemy.orm import Session
from config import settings
from crud import crud
from models.db_models import RecordModel, UserModel
from schemas.models import Place, PlacePagingResponse, RecordPagingResponse, APIResponse, RecordCreate, UserCreate, \
    UserLoginResponse, User
from db.database import get_db
from dependencies import get_current_user_id, get_current_user, create_access_token
from pydantic import BaseModel
from jose import jwt
from datetime import datetime, timedelta
import requests

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=APIResponse)
def create_record(data: UserCreate,
                  db: Session = Depends(get_db)):

    db_user = crud.get_user_by_email(db, email=data.email)
    if db_user:
        raise HTTPException(status_code=400, detail="email already registered")

    db_user = crud.create_user(db=db, user=data)

    return APIResponse(
        success=True,
        message="User created successfully",
        data={"user_id": db_user.id})

app = FastAPI()

SECRET_KEY = "YOUR_SECRET_KEY"
ALGORITHM = "HS256"

class KakaoToken(BaseModel):
    access_token: str

@router.post("/login/kakao")
def kakao_login(data: KakaoToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    res = requests.get("https://kapi.kakao.com/v2/user/me", headers=headers)

    if res.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Kakao token")

    kakao_user = res.json()
    print(kakao_user)
    provider_user_id = str(kakao_user.get("id"))
    kakao_account = kakao_user.get("kakao_account", {})
    profile = kakao_account.get("profile", {})

    email = kakao_account.get("email")
    nickname = profile.get("nickname", "카카오유저")
    profile_image = profile.get("profile_image_url")

    print(email, nickname, profile_image)

    # 1. DB에서 기존 회원 조회
    user = db.query(UserModel).filter(UserModel.provider == "kakao", UserModel.provider_user_id == provider_user_id).first()

    # 2. 없으면 신규 회원 등록
    if not user:
        user = UserModel(
            email=email,
            nickname=nickname,
            profile_image=profile_image,
            provider="kakao",
            provider_user_id=provider_user_id
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        print('user', user)

    access_token = create_access_token(
        data={"sub": str(user.id)}, expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    print('access_token', access_token)
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=UserLoginResponse)
async def read_users_me(current_user: UserModel = Depends(get_current_user)):
    return current_user
