# Firebase CLI 설치 및 로그인 가이드

## 1. Firebase CLI 설치

### 방법 1: npm으로 설치 (권장)
```bash
npm install -g firebase-tools
```

### 방법 2: Chocolatey로 설치 (Windows)
```bash
choco install firebase-cli
```

### 방법 3: 직접 다운로드
- https://firebase.google.com/docs/cli#install-cli-windows

## 2. Firebase 로그인

### 브라우저에서 로그인
```bash
firebase login
```
- 명령어 실행 후 브라우저가 열립니다
- Google 계정으로 로그인하세요
- 권한을 허용하세요

### CI/CD용 토큰 생성 (선택사항)
```bash
firebase login:ci
```

## 3. 프로젝트 확인

### 현재 프로젝트 확인
```bash
firebase projects:list
```

### 프로젝트 설정 확인
```bash
firebase use --add
```

## 4. 배포

### 웹 앱 배포
```bash
firebase deploy --only hosting
```

### 전체 배포
```bash
firebase deploy
```

## 5. 문제 해결

### Firebase CLI 버전 확인
```bash
firebase --version
```

### 로그아웃 후 재로그인
```bash
firebase logout
firebase login
```

### 프로젝트 재설정
```bash
firebase init hosting
```

## 현재 프로젝트 정보
- **프로젝트 ID**: mamama-f2a52
- **웹사이트 URL**: https://mamama-f2a52.web.app
- **설정 파일**: .firebaserc, firebase.json

## 빠른 배포 명령어
```bash
# 1. Firebase CLI 설치
npm install -g firebase-tools

# 2. 로그인
firebase login

# 3. 프로젝트 확인
firebase use mamama-f2a52

# 4. 배포
firebase deploy --only hosting
```
