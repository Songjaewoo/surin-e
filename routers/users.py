from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas.models as models
from db.database import get_db

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[models.User])
async def get_users(
    skip: int = Query(0, ge=0, description="건너뛸 사용자 수"),
    limit: int = Query(100, ge=1, le=1000, description="가져올 사용자 수"),
    db: Session = Depends(get_db)
):
    """모든 사용자를 가져옵니다."""
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@router.get("/{user_id}", response_model=models.User)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """특정 ID의 사용자를 가져옵니다."""
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@router.get("/{user_id}/items", response_model=List[models.Item])
async def get_user_items(user_id: int, db: Session = Depends(get_db)):
    """특정 사용자의 모든 아이템을 가져옵니다."""
    # 사용자 존재 확인
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    items = crud.get_user_items(db, user_id=user_id)
    return items

@router.post("/", response_model=models.User)
async def create_user(user: models.UserCreate, db: Session = Depends(get_db)):
    """새로운 사용자를 생성합니다."""
    # 중복 사용자명 체크
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # 중복 이메일 체크
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    return crud.create_user(db=db, user=user)

@router.put("/{user_id}", response_model=models.User)
async def update_user(
    user_id: int, 
    user: models.UserUpdate, 
    db: Session = Depends(get_db)
):
    """기존 사용자를 업데이트합니다."""
    # 사용자명 중복 체크 (다른 사용자와 중복되는지)
    if user.username:
        existing_user = crud.get_user_by_username(db, username=user.username)
        if existing_user and existing_user.id != user_id:
            raise HTTPException(status_code=400, detail="Username already taken")
    
    # 이메일 중복 체크 (다른 사용자와 중복되는지)
    if user.email:
        existing_user = crud.get_user_by_email(db, email=user.email)
        if existing_user and existing_user.id != user_id:
            raise HTTPException(status_code=400, detail="Email already taken")
    
    db_user = crud.update_user(db, user_id=user_id, user_update=user)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@router.delete("/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """사용자를 삭제합니다."""
    db_user = crud.delete_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully", "user": db_user}

@router.get("/username/{username}", response_model=models.User)
async def get_user_by_username(username: str, db: Session = Depends(get_db)):
    """사용자명으로 사용자를 조회합니다."""
    db_user = crud.get_user_by_username(db, username=username)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user
