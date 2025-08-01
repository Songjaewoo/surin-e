from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from models import db_models
import models

# Item CRUD operations
def get_items(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
    return db.query(db_models.Item).offset(skip).limit(limit).all()

def get_item(db: Session, item_id: int) -> Optional[db_models.Item]:
    return db.query(db_models.Item).filter(db_models.Item.id == item_id).first()

def get_items_by_name(db: Session, name: str) -> List[db_models.Item]:
    return db.query(db_models.Item).filter(
        db_models.Item.name.contains(name)
    ).all()

def create_item(db: Session, item: models.ItemCreate, owner_id: Optional[int] = None) -> db_models.Item:
    db_item = db_models.Item(
        name=item.name,
        description=item.description,
        price=item.price,
        is_available=item.is_available,
        owner_id=owner_id
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def update_item(db: Session, item_id: int, item_update: models.ItemUpdate) -> Optional[db_models.Item]:
    db_item = db.query(db_models.Item).filter(db_models.Item.id == item_id).first()
    if db_item:
        update_data = item_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_item, field, value)
        db.commit()
        db.refresh(db_item)
    return db_item

def delete_item(db: Session, item_id: int) -> Optional[db_models.Item]:
    db_item = db.query(db_models.Item).filter(db_models.Item.id == item_id).first()
    if db_item:
        db.delete(db_item)
        db.commit()
    return db_item

# User CRUD operations
def get_users(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.User]:
    return db.query(db_models.User).offset(skip).limit(limit).all()

def get_user(db: Session, user_id: int) -> Optional[db_models.User]:
    return db.query(db_models.User).filter(db_models.User.id == user_id).first()

def get_user_by_username(db: Session, username: str) -> Optional[db_models.User]:
    return db.query(db_models.User).filter(db_models.User.username == username).first()

def get_user_by_email(db: Session, email: str) -> Optional[db_models.User]:
    return db.query(db_models.User).filter(db_models.User.email == email).first()

def create_user(db: Session, user: models.UserCreate) -> db_models.User:
    db_user = db_models.User(
        username=user.username,
        email=user.email
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: int, user_update: models.UserUpdate) -> Optional[db_models.User]:
    db_user = db.query(db_models.User).filter(db_models.User.id == user_id).first()
    if db_user:
        update_data = user_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_user, field, value)
        db.commit()
        db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: int) -> Optional[db_models.User]:
    db_user = db.query(db_models.User).filter(db_models.User.id == user_id).first()
    if db_user:
        db.delete(db_user)
        db.commit()
    return db_user

# Advanced queries
def search_items(db: Session, query: str, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
    """이름 또는 설명에서 검색"""
    return db.query(db_models.Item).filter(
        or_(
            db_models.Item.name.contains(query),
            db_models.Item.description.contains(query)
        )
    ).offset(skip).limit(limit).all()

def get_available_items(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
    """사용 가능한 아이템만 조회"""
    return db.query(db_models.Item).filter(
        db_models.Item.is_available == True
    ).offset(skip).limit(limit).all()

def get_user_items(db: Session, user_id: int) -> List[db_models.Item]:
    """특정 사용자의 아이템 조회"""
    return db.query(db_models.Item).filter(db_models.Item.owner_id == user_id).all()

def get_items_by_price_range(db: Session, min_price: float, max_price: float) -> List[db_models.Item]:
    """가격 범위로 아이템 조회"""
    return db.query(db_models.Item).filter(
        db_models.Item.price >= min_price,
        db_models.Item.price <= max_price
    ).all()
