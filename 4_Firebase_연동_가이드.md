# 4단계: Firebase 연결 가이드

## 🎯 목표
Firebase 초기화 및 서비스 계층 작성 완료

## 📁 생성된 파일들

### 🔥 Firebase 설정
1. **`lib/firebase_options.dart`** - Firebase 설정 파일
   - Web, Android, iOS 플랫폼별 설정
   - **⚠️ 실제 API 키로 교체 필요**

### 🔧 Firebase 서비스
2. **`lib/services/firebase_service.dart`** - Firebase 서비스 클래스
   - Auth (익명 로그인)
   - Firestore (일기 CRUD)
   - Storage (사진 업로드)
   - 실시간 업데이트 스트림

### 🔄 통합 업데이트
3. **`lib/main.dart`** - Firebase 초기화 추가
4. **`lib/state/app_state_provider.dart`** - Firebase 서비스 통합
5. **`lib/ui/screens/home_screen.dart`** - 로그인 로직 연결

## 🏗️ Firebase 구조

### 📊 Firestore 구조
```
families/
  {familyId}/
    entries/
      {date}/          # 예: 2025-01-16
        - date: string
        - child: {text, emotion, photos[]}
        - parent: {text, emotion, photos[]}
        - comments: []
        - calendarEmoji: string
        - createdAt: timestamp
        - updatedAt: timestamp
```

### 📁 Storage 구조
```
families/
  {familyId}/
    photos/
      {date}/
        {timestamp}_{filename}
```

## 🔧 주요 기능

### ✅ 인증 (Auth)
- **익명 로그인**: `signInAnonymously()`
- **로그아웃**: `signOut()`
- **인증 상태 스트림**: `authStateChanges`

### ✅ Firestore CRUD
- **일기 가져오기**: `getEntry(date)`
- **일기 저장**: `setEntry(date, entry)`
- **섹션 업데이트**: `updateEntrySection(date, section, data)`
- **일기 삭제**: `deleteEntry(date)`
- **월별 일기**: `getThisMonthEntries()`
- **실시간 스트림**: `getEntryStream(date)`

### ✅ Storage
- **사진 업로드**: `uploadPhoto(date, fileBytes, fileName)`
- **사진 삭제**: `deletePhoto(photoUrl)`

### ✅ 댓글 시스템
- **댓글 추가**: `addComment(date, comment)`
- **댓글 업데이트**: `updateComment(date, commentId, updatedComment)`
- **댓글 삭제**: `deleteComment(date, commentId)`

### ✅ 백업/복원
- **데이터 내보내기**: `exportAllData()`
- **데이터 가져오기**: `importData(importData)`

## ⚙️ 설정 필요사항

### 1. Firebase 콘솔 설정
1. [Firebase 콘솔](https://console.firebase.google.com/) 접속
2. 프로젝트 생성: `mind-diary-app`
3. 서비스 활성화:
   - Authentication → 익명 로그인 활성화
   - Firestore Database → 테스트 모드
   - Storage → 테스트 모드
   - Hosting → 설정

### 2. FlutterFire CLI 설치 및 설정
```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 설정
flutterfire configure
```

### 3. firebase_options.dart 업데이트
생성된 파일의 API 키들을 실제 값으로 교체:
```dart
apiKey: 'AIzaSyB...', // 실제 API 키
appId: '1:123456789012:web:abcdef...', // 실제 App ID
projectId: 'mind-diary-app', // 실제 프로젝트 ID
```

## 🔄 상태관리 통합

### AppStateProvider 업데이트
- Firebase 서비스 인스턴스 추가
- 로그인/로그아웃 시 Firebase 연동
- 로컬 저장소와 Firebase 동기화

### HomeScreen 업데이트
- Provider를 통한 Firebase 로그인
- 로딩 상태 및 에러 처리

## 🚀 다음 단계 준비사항

1. **Firebase 프로젝트 생성** 및 서비스 활성화
2. **FlutterFire CLI** 설정으로 실제 API 키 생성
3. **firebase_options.dart** 실제 값으로 교체
4. **테스트**: `flutter run -d chrome`으로 Firebase 연동 확인

## 📋 체크리스트
- ✅ firebase_options.dart 생성
- ✅ Auth(익명 로그인), Firestore, Storage 초기화
- ✅ FirebaseService: signInAnonymously(), getEntry(), setEntry(), uploadPhoto()
- ✅ Firestore 구조: families/{familyId}/entries/{date}
- ✅ Storage 구조: families/{familyId}/photos/{date}/{filename}
- ✅ main.dart Firebase 초기화
- ✅ AppStateProvider Firebase 통합
- ✅ HomeScreen 로그인 로직 연결

---

**📅 완료일**: 2025년 1월 16일  
**👤 작성자**: 파이썬 기초 수업 학생  
**📝 버전**: v1.0
