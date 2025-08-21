from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr, model_validator
from datetime import date, time, datetime


class Place(BaseModel):
    id: int
    name: str
    address: str
    image_url: Optional[str] = 'http://imgnews.naver.net/image/5165/2017/07/17/0000310698_001_20170717221957660.jpg'
    x_position: str
    y_position: str
    is_bookmark: Optional[bool] = False

    class Config:
        from_attributes = True

class PlaceCreate(BaseModel):
    name: str
    address: str
    x_position: str
    y_position: str
    image_url: Optional[str] = None

class PlaceUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    x_position: Optional[str] = None
    y_position: Optional[str] = None
    image_url: Optional[str] = None

class PlacePagingResponse(BaseModel):
    total: int
    result: List[Place]

class BookmarkBase(BaseModel):
    id: int
    place_id: int

    class Config:
        from_attributes = True

class Bookmark(BaseModel):
    id: int
    place_id: int
    place: Place

    class Config:
        from_attributes = True

class BookmarkCreate(BaseModel):
    place_id: int

class BookmarkPagingResponse(BaseModel):
    total: int
    result: List[Bookmark]

class Record(BaseModel):
    id: int
    user_id: int
    place_id: int
    record_date: date
    start_time: time
    end_time: time
    pool_length: float
    swim_distance: int
    memo: str
    created_at: datetime
    updated_at: datetime
    place : Place

    class Config:
        from_attributes = True

class RecordCreate(BaseModel):
    place_id: int
    record_date: date = date.today()
    start_time: time = datetime.now().time()
    end_time: time = datetime.now().time()
    pool_length: float = 25
    swim_distance: int = 0
    memo: str = ''

class RecordPagingResponse(BaseModel):
    total: int
    result: List[Record]

class User(BaseModel):
    id: int
    nickname: str
    email: str
    password: str
    profile_image : str
    provider: str
    provider_user_id: str
    created_at: datetime
    updated_at: datetime
    bookmarks: List[Bookmark]

    class Config:
        from_attributes = True

class UserLoginResponse(BaseModel):
    id: int
    nickname: str
    email: str
    profile_image: Optional[str] = None
    provider: Optional[str] = None

class UserCreate(BaseModel):
    nickname: Optional[str] = None
    email: EmailStr
    password: Optional[str] = None
    profile_image: Optional[str] = None
    provider: Optional[str] = None
    provider_user_id: Optional[str] = None
    created_at: Optional[datetime] = datetime.now()
    updated_at: Optional[datetime] = datetime.now()

# JWT 로그인 요청 시 필요한 모델
class Token(BaseModel):
    access_token: str
    token_type: str

# 토큰 페이로드 모델
class TokenData(BaseModel):
    user_id: str = None

class AccessToken(BaseModel):
    access_token: str

# API 응답 모델
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    detail: Optional[str] = None
