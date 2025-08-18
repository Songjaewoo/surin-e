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
import time

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


class NaverToken(BaseModel):
    access_token: str

class GoogleToken(BaseModel):
    access_token: str

@router.post("/login/kakao")
def kakao_login(data: NaverToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    res = requests.get("https://kapi.kakao.com/v2/user/me", headers=headers)

    if res.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Kakao token")

    kakao_user = res.json()
    provider_user_id = str(kakao_user.get("id"))
    kakao_account = kakao_user.get("kakao_account", {})
    profile = kakao_account.get("profile", {})

    email = kakao_account.get("email")
    nickname = profile.get("nickname", "카카오유저")
    profile_image = profile.get("profile_image_url")

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

@router.post("/login/naver")
def naver_login(data: KakaoToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    try:
        # 네이버 사용자 정보 조회 API 호출
        res = requests.get("https://openapi.naver.com/v1/nid/me", headers=headers)
        res.raise_for_status()  # 200 OK가 아니면 예외 발생

        naver_user = res.json().get('response', {})
        if not naver_user:
            raise HTTPException(status_code=400, detail="Invalid Naver token or empty response")

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Failed to get user info from Naver: {e}")

    print(naver_user)

    # 네이버 API 응답에서 사용자 정보 추출
    provider_user_id = str(naver_user.get("id"))
    email = naver_user.get("email")
    nickname = naver_user.get("nickname", "네이버유저")
    profile_image = naver_user.get("profile_image", "")

    # 1. DB에서 기존 회원 조회
    user = db.query(UserModel).filter(
        UserModel.provider == "naver",
        UserModel.provider_user_id == provider_user_id
    ).first()

    # 2. 없으면 신규 회원 등록
    if not user:
        user = UserModel(
            email=email,
            nickname=nickname,
            profile_image=profile_image,
            provider="naver",
            provider_user_id=provider_user_id
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        print('user', user)

    # 3. JWT 토큰 생성 및 반환
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    print('access_token', access_token)

    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/login/google")
async def google_login(data: GoogleToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    res = requests.get("https://www.googleapis.com/oauth2/v2/userinfo", headers=headers)

    if res.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Google token")

    google_user = res.json()
    provider_user_id = google_user.get("id")
    email = google_user.get("email")
    nickname = google_user.get("name", "구글유저")
    profile_image = google_user.get("picture", "")


    user = db.query(UserModel).filter(
        UserModel.provider == "google",
        UserModel.provider_user_id == provider_user_id
    ).first()

    # 2. 없으면 신규 회원 등록
    if not user:
        user = UserModel(
            email=email,
            nickname=nickname,
            profile_image=profile_image,
            provider="google",
            provider_user_id=provider_user_id
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # 3. JWT 토큰 생성 및 반환
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserLoginResponse)
async def read_users_me(current_user: UserModel = Depends(get_current_user)):
    return current_user
