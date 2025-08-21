from fastapi import APIRouter, HTTPException, Depends, Query, FastAPI, Body, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from config import settings
from crud import crud
from models.db_models import RecordModel, UserModel
from schemas.models import Place, PlacePagingResponse, RecordPagingResponse, APIResponse, RecordCreate, UserCreate, \
    UserLoginResponse, User, AccessToken, Token
from db.database import get_db
from dependencies import get_current_user_id, get_current_user, create_access_token
import requests
from util.create_nickname import NicknameGenerator

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/", response_model=APIResponse)
def create_record(data: UserCreate,
                  db: Session = Depends(get_db)):

    db_user = crud.get_user_by_email(db, email=data.email)
    if db_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="email already registered")

    nickname_generator = NicknameGenerator()
    random_nickname = nickname_generator.create()
    exist_nickname = crud.exist_nickname(db, random_nickname)
    while exist_nickname:
        random_nickname = nickname_generator.create()
        exist_nickname = crud.exist_nickname(db, random_nickname)

    data.nickname = random_nickname
    db_user = crud.create_user(db=db, user=data)

    return APIResponse(
        success=True,
        message="User created successfully",
        data={"user_id": db_user.id})

@router.post("/login/local", response_model=Token)
async def login_for_access_token(email: str = Body(..., description="사용자 이메일"),
                                 password: str = Body(..., description="사용자 비밀번호"),
                                 db: Session = Depends(get_db)):

    user = crud.get_user_by_email(db, email=email)
    if not user or not pwd_context.verify(password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    access_token = create_access_token(
        data={"sub": str(user.id)}, expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return Token(access_token=access_token, token_type="bearer")

@router.post("/login/kakao", response_model=Token)
def kakao_login(data: AccessToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    res = requests.get("https://kapi.kakao.com/v2/user/me", headers=headers)

    if res.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Kakao token")

    kakao_user = res.json()
    provider = 'kakao'
    provider_user_id = str(kakao_user.get("id"))
    kakao_account = kakao_user.get("kakao_account", {})
    email = kakao_account.get("email")

    user = crud.get_social_user(db, provider_user_id, provider)

    if not user:
        nickname_generator = NicknameGenerator()
        random_nickname = nickname_generator.create()
        exist_nickname = crud.exist_nickname(db, random_nickname)
        while exist_nickname:
            random_nickname = nickname_generator.create()
            exist_nickname = crud.exist_nickname(db, random_nickname)

        user = crud.create_social_user(db, email, random_nickname, provider_user_id, provider)

    access_token = create_access_token(
        data={"sub": str(user.id)}, expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return Token(access_token=access_token, token_type="bearer")

@router.post("/login/naver", response_model=Token)
def naver_login(data: AccessToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    try:
        res = requests.get("https://openapi.naver.com/v1/nid/me", headers=headers)
        res.raise_for_status()  # 200 OK가 아니면 예외 발생

        naver_user = res.json().get('response', {})
        if not naver_user:
            raise HTTPException(status_code=400, detail="Invalid Naver token or empty response")

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Failed to get user info from Naver: {e}")

    provider = 'naver'
    provider_user_id = str(naver_user.get("id"))
    email = naver_user.get("email")

    user = crud.get_social_user(db, provider_user_id, provider)

    if not user:
        nickname_generator = NicknameGenerator()
        random_nickname = nickname_generator.create()
        exist_nickname = crud.exist_nickname(db, random_nickname)
        while exist_nickname:
            random_nickname = nickname_generator.create()
            exist_nickname = crud.exist_nickname(db, random_nickname)

        user = crud.create_social_user(db, email, random_nickname, provider_user_id, provider)

    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return Token(access_token=access_token, token_type="bearer")


@router.post("/login/google", response_model=Token)
async def google_login(data: AccessToken, db: Session = Depends(get_db)):
    headers = {"Authorization": f"Bearer {data.access_token}"}
    res = requests.get("https://www.googleapis.com/oauth2/v2/userinfo", headers=headers)

    if res.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Google token")

    google_user = res.json()
    provider = 'google'
    provider_user_id = google_user.get("id")
    email = google_user.get("email")

    user = crud.get_social_user(db, provider_user_id, provider)

    if not user:
        nickname_generator = NicknameGenerator()
        random_nickname = nickname_generator.create()
        exist_nickname = crud.exist_nickname(db, random_nickname)
        while exist_nickname:
            random_nickname = nickname_generator.create()
            exist_nickname = crud.exist_nickname(db, random_nickname)

        user = crud.create_social_user(db, email, random_nickname, provider_user_id, provider)

    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )

    return Token(access_token=access_token, token_type="bearer")

@router.get("/me", response_model=UserLoginResponse)
async def read_users_me(current_user: UserModel = Depends(get_current_user)):
    return current_user
