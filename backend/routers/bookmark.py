from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from crud import crud
from schemas.models import BookmarkPagingResponse, APIResponse, BookmarkCreate
from db.database import get_db
from dependencies import get_current_user_id

router = APIRouter(
    prefix="/bookmarks",
    tags=["bookmarks"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=BookmarkPagingResponse)
async def get_bookmarks(
        page: int = Query(1, ge=1, description="페이지 번호 (1부터 시작)"),
        size: int = Query(10, ge=1, le=50, description="페이지당 항목 수 (최대 50)"),
        search: Optional[str] = Query('', description="검색할 장소 이름"),
        db: Session = Depends(get_db),
        current_user_id = Depends(get_current_user_id)):

    offset = (page - 1) * size
    total_count, result = crud.get_bookmarks(db, offset=offset, limit=size, search=search, current_user_id=current_user_id)

    return {"total": total_count, "result": result}


@router.post("/", response_model=APIResponse)
async def create_bookmark(
        data: BookmarkCreate,
        db: Session = Depends(get_db),
        current_user_id = Depends(get_current_user_id)):

    bookmark = crud.create_bookmark(db, place_id=data.place_id, user_id=current_user_id)
    if bookmark is None:
        raise HTTPException(status_code=404, detail="Place not found")

    return APIResponse(
        success=True,
        message="Bookmark created successfully",
        data={"bookmark_id": bookmark.id})

@router.delete("/{place_id}", response_model=APIResponse)
async def delete_bookmark(
        place_id: int,
        db: Session = Depends(get_db),
        current_user_id = Depends(get_current_user_id)):

    result = crud.delete_bookmark(db, place_id=place_id, user_id=current_user_id)

    return APIResponse(
        success=result,
        message="Bookmark deleted successfully")


