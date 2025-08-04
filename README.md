# Surin-e Project

장소 북마크 및 추천 서비스

## 프로젝트 구조

```
surin-e/
├── backend/          # FastAPI 백엔드 서버
├── mobile/           # Flutter 모바일 앱
├── shared/           # 공통 리소스 및 문서
└── README.md
```

## 개발 환경 설정

### Backend (FastAPI)
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

## API 서버 실행
```bash
cd backend
source .venv/bin/activate
uvicorn main:app --reload
```

## 모바일 앱 실행
```bash
cd mobile
flutter run
```

## 데이터베이스 마이그레이션
```bash
cd backend
alembic upgrade head
```
