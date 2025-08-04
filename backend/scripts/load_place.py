import json
import os
import sys
from sqlalchemy.orm import Session

# --- 프로젝트 경로 설정 ---
# 이 스크립트를 어느 위치에서 실행하든 프로젝트의 모듈을 찾을 수 있도록 경로를 설정합니다.
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.append(project_root)
# -------------------------

from db.database import SessionLocal, engine
from models.db_models import Place, Base


def load_places_from_json(db: Session, json_path: str):
    """
    jonghab.json 파일을 읽어 '영업/정상' 상태인 장소 데이터를
    데이터베이스에 저장합니다.
    - 이미 존재하는 데이터는 건너뜁니다.
    - 필수 정보(도로명주소, 좌표)가 없거나 유효하지 않으면 건너뜁니다.
    """
    print(f"Attempting to load JSON file from: {json_path}")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"오류: {json_path} 에서 파일을 찾을 수 없습니다.")
        return
    except json.JSONDecodeError:
        print(f"오류: {json_path} 파일의 JSON 형식이 올바르지 않습니다.")
        return

    # 성능 향상을 위해 기존 데이터를 메모리에 세트로 로드
    print("기존 장소 데이터를 로드하여 중복을 확인합니다...")
    existing_places = {(p.name, p.address) for p in db.query(Place.name, Place.address).all()}
    print(f"현재 데이터베이스에 {len(existing_places)}개의 장소가 있습니다.")

    places_to_add = []
    records = data.get("DATA", [])

    print(f"JSON 파일에서 {len(records)}개의 레코드를 발견했습니다. 데이터 처리를 시작합니다...")

    for record in records:
        # 1. '영업/정상' 상태인 데이터만 필터링
        if record.get("trdstatenm") != "영업/정상":
            continue

        # 2. 필수 데이터 추출 (도로명 주소를 우선 사용)
        name = record.get("bplcnm")
        address = record.get("rdnwhladdr")
        x_str = record.get("x")
        y_str = record.get("y")

        # 3. 데이터 유효성 검사 (이름, 주소, 좌표 값이 모두 있어야 함)
        if not all([name, address, x_str, y_str]):
            continue

        # 4. 데이터 타입 변환 및 정리
        try:
            # 좌표 값의 양쪽 공백을 제거하고 float으로 변환
            x_pos = float(x_str.strip())
            y_pos = float(y_str.strip())
        except (ValueError, AttributeError):
            # 변환 실패 시 해당 레코드 건너뛰기
            print(f"좌표 변환 실패로 레코드를 건너뜁니다: name='{name}'")
            continue

        # 5. 중복 데이터 확인
        if (name, address) in existing_places:
            continue

        # 6. Place 객체 생성 및 리스트에 추가
        new_place = Place(
            name=name,
            address=address,
            x_position=x_pos,
            y_position=y_pos
        )
        places_to_add.append(new_place)
        existing_places.add((name, address))  # 현재 세션 내 중복 방지

    if not places_to_add:
        print("추가할 새로운 장소 데이터가 없습니다.")
        return

    print(f"데이터베이스에 {len(places_to_add)}개의 새로운 장소를 추가합니다...")
    # 여러 객체를 한 번에 저장하여 성능 최적화
    db.bulk_save_objects(places_to_add)
    db.commit()
    print("성공적으로 데이터베이스에 커밋했습니다.")


if __name__ == "__main__":
    # JSON 파일 경로 설정 (프로젝트 루트 기준)
    json_file_path = os.path.join(project_root, 'scripts/jonghab.json')

    # 데이터베이스 테이블이 없으면 생성
    print("데이터베이스 테이블을 확인하고 필요시 생성합니다...")
    Base.metadata.create_all(bind=engine)

    # 데이터베이스 세션 생성
    db = SessionLocal()
    try:
        load_places_from_json(db, json_file_path)
    except Exception as e:
        print(f"예상치 못한 오류가 발생했습니다: {e}")
        db.rollback()
    finally:
        db.close()
        print("데이터베이스 세션을 닫았습니다.")

    json_file_path = os.path.join(project_root, 'scripts/seoul.json')
    # 데이터베이스 세션 생성
    db = SessionLocal()
    try:
        load_places_from_json(db, json_file_path)
    except Exception as e:
        print(f"예상치 못한 오류가 발생했습니다: {e}")
        db.rollback()
    finally:
        db.close()
        print("데이터베이스 세션을 닫았습니다.")
