# Backend API Server

FastAPI 기반의 장소 북마크 및 추천 API 서버

## 실행 방법

### 1. 가상환경 설정
```bash
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate   # Windows
```

### 2. 의존성 설치
```bash
pip install -r requirements.txt
```

### 3. 데이터베이스 마이그레이션
```bash
alembic upgrade head
```

### 4. 서버 실행
```bash
uvicorn main:app --reload
```

API 문서: http://localhost:8000/docs

## 프로젝트 구조
```
backend/
├── main.py              # FastAPI 앱 진입점
├── config.py            # 설정 파일
├── dependencies.py      # 의존성 관리
├── requirements.txt     # Python 패키지 목록
├── alembic.ini         # Alembic 설정
├── routers/            # API 라우터
├── models/             # 데이터베이스 모델
├── schemas/            # Pydantic 스키마
├── crud/               # CRUD 작업
├── db/                 # 데이터베이스 설정
├── migrations/         # Alembic 마이그레이션
└── scripts/            # 유틸리티 스크립트
```
