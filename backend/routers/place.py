from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from crud import crud
from schemas.models import Place, PlacePagingResponse
from db.database import get_db
from dependencies import get_current_user_id

router = APIRouter(
    prefix="/places",
    tags=["places"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=PlacePagingResponse)
async def get_places(
        page: int = Query(1, ge=1, description="페이지 번호 (1부터 시작)"),
        size: int = Query(10, ge=1, le=50, description="페이지당 항목 수 (최대 50)"),
        search: str = Query('', description="검색할 장소 이름"),
        db: Session = Depends(get_db),
        current_user_id: int = Depends(get_current_user_id)):

    offset = (page - 1) * size
    total_count, result = crud.get_places(db, offset=offset, limit=size, search=search, current_user_id=current_user_id)

    return {"total": total_count, "result": result}

@router.get("/{place_id}", response_model=Place)
async def get_place_detail(
        place_id: int,
        db: Session = Depends(get_db),
        current_user_id: int = Depends(get_current_user_id)):

    result = crud.get_place_detail(db, place_id=place_id, current_user_id=current_user_id)

    if result is None:
        raise HTTPException(status_code=404, detail="Place not found")

    return result

