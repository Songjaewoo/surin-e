from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from sqlalchemy.sql.expression import case, literal, and_
from typing import List, Optional, Tuple
from models.db_models import PlaceModel, BookmarkModel
from schemas.models import Place, Bookmark

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

# Item CRUD operations
# def get_items(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
#     return db.query(db_models.Item).offset(skip).limit(limit).all()
#
# def get_item(db: Session, item_id: int) -> Optional[db_models.Item]:
#     return db.query(db_models.Item).filter(db_models.Item.id == item_id).first()
#
# def get_items_by_name(db: Session, name: str) -> List[db_models.Item]:
#     return db.query(db_models.Item).filter(
#         db_models.Item.name.contains(name)
#     ).all()
#
# def create_item(db: Session, item: models.ItemCreate, owner_id: Optional[int] = None) -> db_models.Item:
#     db_item = db_models.Item(
#         name=item.name,
#         description=item.description,
#         price=item.price,
#         is_available=item.is_available,
#         owner_id=owner_id
#     )
#     db.add(db_item)
#     db.commit()
#     db.refresh(db_item)
#     return db_item
#
# def update_item(db: Session, item_id: int, item_update: models.ItemUpdate) -> Optional[db_models.Item]:
#     db_item = db.query(db_models.Item).filter(db_models.Item.id == item_id).first()
#     if db_item:
#         update_data = item_update.dict(exclude_unset=True)
#         for field, value in update_data.items():
#             setattr(db_item, field, value)
#         db.commit()
#         db.refresh(db_item)
#     return db_item
#
# def delete_item(db: Session, item_id: int) -> Optional[db_models.Item]:
#     db_item = db.query(db_models.Item).filter(db_models.Item.id == item_id).first()
#     if db_item:
#         db.delete(db_item)
#         db.commit()
#     return db_item
#
# # User CRUD operations
# def get_users(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.User]:
#     return db.query(db_models.User).offset(skip).limit(limit).all()
#
# def get_user(db: Session, user_id: int) -> Optional[db_models.User]:
#     return db.query(db_models.User).filter(db_models.User.id == user_id).first()
#
# def get_user_by_username(db: Session, username: str) -> Optional[db_models.User]:
#     return db.query(db_models.User).filter(db_models.User.username == username).first()
#
# def get_user_by_email(db: Session, email: str) -> Optional[db_models.User]:
#     return db.query(db_models.User).filter(db_models.User.email == email).first()
#
# def create_user(db: Session, user: models.UserCreate) -> db_models.User:
#     db_user = db_models.User(
#         username=user.username,
#         email=user.email
#     )
#     db.add(db_user)
#     db.commit()
#     db.refresh(db_user)
#     return db_user
#
# def update_user(db: Session, user_id: int, user_update: models.UserUpdate) -> Optional[db_models.User]:
#     db_user = db.query(db_models.User).filter(db_models.User.id == user_id).first()
#     if db_user:
#         update_data = user_update.dict(exclude_unset=True)
#         for field, value in update_data.items():
#             setattr(db_user, field, value)
#         db.commit()
#         db.refresh(db_user)
#     return db_user
#
# def delete_user(db: Session, user_id: int) -> Optional[db_models.User]:
#     db_user = db.query(db_models.User).filter(db_models.User.id == user_id).first()
#     if db_user:
#         db.delete(db_user)
#         db.commit()
#     return db_user
#
# # Advanced queries
# def search_items(db: Session, query: str, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
#     """이름 또는 설명에서 검색"""
#     return db.query(db_models.Item).filter(
#         or_(
#             db_models.Item.name.contains(query),
#             db_models.Item.description.contains(query)
#         )
#     ).offset(skip).limit(limit).all()
#
# def get_available_items(db: Session, skip: int = 0, limit: int = 100) -> List[db_models.Item]:
#     """사용 가능한 아이템만 조회"""
#     return db.query(db_models.Item).filter(
#         db_models.Item.is_available == True
#     ).offset(skip).limit(limit).all()
#
# def get_user_items(db: Session, user_id: int) -> List[db_models.Item]:
#     """특정 사용자의 아이템 조회"""
#     return db.query(db_models.Item).filter(db_models.Item.owner_id == user_id).all()
#
# def get_items_by_price_range(db: Session, min_price: float, max_price: float) -> List[db_models.Item]:
#     """가격 범위로 아이템 조회"""
#     return db.query(db_models.Item).filter(
#         db_models.Item.price >= min_price,
#         db_models.Item.price <= max_price
#     ).all()
