from __future__ import annotations
from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr, model_validator
from datetime import datetime


class Place(BaseModel):
    id: int
    name: str
    address: str
    image_url: Optional[str] = 'http://imgnews.naver.net/image/5165/2017/07/17/0000310698_001_20170717221957660.jpg'
    x_position: float
    y_position: float
    is_bookmark: Optional[bool] = False

    class Config:
        from_attributes = True

class PlaceCreate(BaseModel):
    name: str
    address: str
    x_position: float
    y_position: float

class PlaceUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    x_position: Optional[float] = None
    y_position: Optional[float] = None

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

class User(BaseModel):
    id: int
    nickname: str
    email: str
    bookmarks: List[Bookmark]

    class Config:
        from_attributes = True

class UserLoginResponse(BaseModel):
    id: int
    nickname: str
    email: str

class UserCreate(BaseModel):
    nickname: str
    email: Optional[EmailStr] = None
    password: str

# JWT 로그인 요청 시 필요한 모델
class Token(BaseModel):
    access_token: str
    token_type: str

# 토큰 페이로드 모델
class TokenData(BaseModel):
    user_id: str = None


# API 응답 모델
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    detail: Optional[str] = None
