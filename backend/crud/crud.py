from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from sqlalchemy.sql.expression import case, literal, and_
from typing import List, Optional, Tuple
from models.db_models import PlaceModel, BookmarkModel, UserModel, RecordModel
from schemas.models import Place, Bookmark, UserCreate, User, Record
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_records(db: Session,
                offset: int,
                limit: int,
                current_user_id: int) -> Tuple[int, List[Record]]:

    query = db.query(RecordModel)
    query = query.filter(RecordModel.user_id == current_user_id)

    total_count = query.count()

    result = (query.options(joinedload(RecordModel.place))
                .order_by(RecordModel.record_date.desc())
                .order_by(RecordModel.start_time.desc())
                .offset(offset)
                .limit(limit)
                .all())

    return total_count, result


def create_record(db, data, current_user_id):
    record = RecordModel(
        user_id=current_user_id,
        place_id=data.place_id,
        record_date=data.record_date,
        start_time=data.start_time,
        end_time=data.end_time,
        pool_length=data.pool_length,
        swim_distance=data.swim_distance,
        memo=data.memo
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    return record
def get_record_detail(db, record_id, current_user_id):
    return None
def get_places(db: Session,
               offset: int,
               limit: int,
               search: Optional[str] = None,
               current_user_id: Optional[int] = None) -> Tuple[int, List[Place]]: # 반환 타입도 수정

    # 1. total_count를 위한 쿼리 빌드
    count_query = db.query(func.count(PlaceModel.id))

    trim_search = search.strip()
    if trim_search:
        count_query = count_query.filter(PlaceModel.name.like(f"%{trim_search}%"))

    total_count = count_query.scalar()

    # 2. place 데이터를 가져오기 위한 메인 쿼리 빌드
    # 메인 쿼리는 항상 PlaceModel을 기본으로 시작합니다.
    main_query = db.query(PlaceModel)

    if search:
        trim_search = search.strip()
        if trim_search:
            main_query = main_query.filter(PlaceModel.name.like(f"%{trim_search}%"))

    # 3. 로그인 상태에 따라 is_bookmarked 필드를 추가
    is_bookmarked_case = case(
        (BookmarkModel.id.isnot(None), True),
        else_=False
    ).label("is_bookmark")

    if current_user_id:
        main_query = main_query.add_columns(is_bookmarked_case).outerjoin(
            BookmarkModel,
            and_(
                BookmarkModel.place_id == PlaceModel.id,
                BookmarkModel.user_id == current_user_id
            )
        )
    else:
        main_query = main_query.add_columns(literal(False).label("is_bookmark"))

    # 4. 페이징 적용
    places_data = main_query.offset(offset).limit(limit).all()

    # 5. 결과 변환 (튜플 형태로 반환되므로 그대로 사용)
    result = []
    for place_model, is_bookmark in places_data:
        place_data = Place.model_validate(place_model)
        place_data.is_bookmark = is_bookmark
        result.append(place_data)

    return total_count, result

def get_place_detail(db: Session,
                     place_id: int,
                     current_user_id: Optional[int]) -> Optional[Place]:

    # 1. is_bookmarked 필드를 위한 case 문 생성
    is_bookmarked_case = case(
        (BookmarkModel.id.isnot(None), True),
        else_=False
    ).label("is_bookmarked")

    # 2. 메인 쿼리 구성
    if current_user_id:
        # 로그인 유저가 있는 경우: outerjoin으로 북마크 여부 확인
        query = db.query(PlaceModel, is_bookmarked_case).outerjoin(
            BookmarkModel,
            and_(
                BookmarkModel.place_id == PlaceModel.id,
                BookmarkModel.user_id == current_user_id
            )
        )
    else:
        # 로그인 유저가 없는 경우: join 없이 is_bookmarked를 항상 False로 고정
        query = db.query(PlaceModel, literal(False).label("is_bookmarked"))

    # 3. place_id로 필터링하고 첫 번째 결과 가져오기
    place_data = query.filter(PlaceModel.id == place_id).first()
    place_model, is_bookmark= place_data

    # 5. Pydantic 모델로 변환
    result = Place.model_validate(place_model)
    result.is_bookmark = is_bookmark

    return result

def get_bookmarks(db: Session,
                  offset: int,
                  limit: int,
                  search: str,
                  current_user_id: Optional[int]) -> tuple[int, list[Bookmark]]:

    query = db.query(BookmarkModel).options(joinedload(BookmarkModel.place))
    query = query.filter(BookmarkModel.user_id == current_user_id)

    trim_search = search.strip()
    if trim_search:
        query = query.join(PlaceModel).filter(PlaceModel.name.like(f"%{trim_search}%"))

    total_count = query.count()
    if total_count == 0:
        return total_count, []

    result = query.offset(offset).limit(limit).all()

    return total_count, result

def create_bookmark(db: Session, place_id: int, user_id: int):
    bookmark = BookmarkModel(place_id=place_id, user_id=user_id)
    db.add(bookmark)
    db.commit()
    db.refresh(bookmark)

    return bookmark

def delete_bookmark(db: Session, place_id: int, user_id: int):
    bookmark = db.query(BookmarkModel).filter(
        BookmarkModel.place_id == place_id,
        BookmarkModel.user_id == user_id
    ).first()

    if bookmark:
        db.delete(bookmark)
        db.commit()

        return True

    return False

def get_user_by_email(db: Session, email: str) -> User:
    return db.query(UserModel).filter(UserModel.email == email).first()

def create_user(db: Session, user: UserCreate):
    hash_password = pwd_context.hash(user.password)
    db_user = UserModel(
        nickname=user.nickname,
        email=user.email,
        password=hash_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

def get_user_by_id(db: Session, user_id: str):
    return db.query(UserModel).filter(UserModel.id == user_id).first()


