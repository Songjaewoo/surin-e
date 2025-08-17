from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from crud import crud
from models.db_models import RecordModel
from schemas.models import Place, PlacePagingResponse, RecordPagingResponse, APIResponse, RecordCreate
from db.database import get_db
from dependencies import get_current_user_id

router = APIRouter(
    prefix="/records",
    tags=["records"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=RecordPagingResponse)
def get_records(
        page: int = Query(1, ge=1, description="페이지 번호 (1부터 시작)"),
        size: int = Query(10, ge=1, le=50, description="페이지당 항목 수 (최대 50)"),
        db: Session = Depends(get_db),
        current_user_id: int = Depends(get_current_user_id)):

    offset = (page - 1) * size
    total_count, result = crud.get_records(db=db, offset=offset, limit=size, current_user_id=current_user_id)

    return {"total": total_count, "result": result}

@router.post("/", response_model=APIResponse)
def create_record(data: RecordCreate,
                  db: Session = Depends(get_db),
                  current_user_id: int = Depends(get_current_user_id)):

    result = crud.create_record(db, data, current_user_id)

    return APIResponse(
        success=True,
        message="Record created successfully",
        data={"record_id": result.id})

@router.get("/{record_id}", response_model=Place)
def get_record_detail(
        record_id: int,
        db: Session = Depends(get_db),
        current_user_id: int = Depends(get_current_user_id)):

    result = crud.get_record_detail(db, record_id=record_id, current_user_id=current_user_id)

    if result is None:
        raise HTTPException(status_code=404, detail="Place not found")

    return result

