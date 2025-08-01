from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import crud
import schemas.models as models
from db.database import get_db

router = APIRouter(
    prefix="/items",
    tags=["items"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[models.Item])
async def get_items(
    skip: int = Query(0, ge=0, description="건너뛸 아이템 수"),
    limit: int = Query(100, ge=1, le=1000, description="가져올 아이템 수"),
    available_only: bool = Query(False, description="사용 가능한 아이템만 조회"),
    db: Session = Depends(get_db)
):
    """모든 아이템을 가져옵니다."""
    if available_only:
        items = crud.get_available_items(db, skip=skip, limit=limit)
    else:
        items = crud.get_items(db, skip=skip, limit=limit)
    return items

@router.get("/search", response_model=List[models.Item])
async def search_items(
    q: str = Query(..., min_length=1, description="검색어"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """아이템을 검색합니다."""
    items = crud.search_items(db, query=q, skip=skip, limit=limit)
    return items

@router.get("/price-range", response_model=List[models.Item])
async def get_items_by_price_range(
    min_price: float = Query(..., ge=0, description="최소 가격"),
    max_price: float = Query(..., ge=0, description="최대 가격"),
    db: Session = Depends(get_db)
):
    """가격 범위로 아이템을 조회합니다."""
    if min_price > max_price:
        raise HTTPException(status_code=400, detail="최소 가격이 최대 가격보다 클 수 없습니다")
    
    items = crud.get_items_by_price_range(db, min_price, max_price)
    return items

@router.get("/{item_id}", response_model=models.Item)
async def get_item(item_id: int, db: Session = Depends(get_db)):
    """특정 ID의 아이템을 가져옵니다."""
    db_item = crud.get_item(db, item_id=item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item

@router.post("/", response_model=models.Item)
async def create_item(
    item: models.ItemCreate, 
    owner_id: Optional[int] = Query(None, description="아이템 소유자 ID"),
    db: Session = Depends(get_db)
):
    """새로운 아이템을 생성합니다."""
    # 소유자 ID가 제공된 경우 유효성 검사
    if owner_id:
        owner = crud.get_user(db, user_id=owner_id)
        if not owner:
            raise HTTPException(status_code=404, detail="Owner not found")
    
    return crud.create_item(db=db, item=item, owner_id=owner_id)

@router.put("/{item_id}", response_model=models.Item)
async def update_item(
    item_id: int, 
    item: models.ItemUpdate, 
    db: Session = Depends(get_db)
):
    """기존 아이템을 업데이트합니다."""
    db_item = crud.update_item(db, item_id=item_id, item_update=item)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item

@router.delete("/{item_id}")
async def delete_item(item_id: int, db: Session = Depends(get_db)):
    """아이템을 삭제합니다."""
    db_item = crud.delete_item(db, item_id=item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return {"message": "Item deleted successfully", "item": db_item}
