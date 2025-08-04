# Mobile App

Flutter 기반의 장소 북마크 및 추천 모바일 앱

## 개발 환경 설정

### 1. Flutter 설치
Flutter 공식 문서를 참고하여 Flutter SDK를 설치하세요.
- https://docs.flutter.dev/get-started/install

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 앱 실행
```bash
# 디버그 모드
flutter run

# 특정 기기에서 실행
flutter run -d <device_id>

# 사용 가능한 기기 목록 확인
flutter devices
```

## 빌드

### Android APK
```bash
flutter build apk
```

### iOS (macOS에서만)
```bash
flutter build ios
```

## 프로젝트 구조 (예정)
```
mobile/
├── lib/
│   ├── main.dart           # 앱 진입점
│   ├── models/             # 데이터 모델
│   ├── screens/            # 화면 위젯
│   ├── widgets/            # 재사용 가능한 위젯
│   ├── services/           # API 서비스
│   └── utils/              # 유틸리티
├── android/                # Android 설정
├── ios/                    # iOS 설정
└── pubspec.yaml           # Flutter 패키지 설정
```

## API 서버 연결
백엔드 API 서버 주소: `http://localhost:8000`
