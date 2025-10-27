@echo off
echo ========================================
echo 마음일기장 Firebase 배포 스크립트
echo ========================================

echo.
echo 1. Firebase CLI 설치 확인 중...
firebase --version
if %errorlevel% neq 0 (
    echo Firebase CLI가 설치되지 않았습니다.
    echo 다음 명령어로 설치하세요: npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo 2. Firebase 로그인 상태 확인 중...
firebase projects:list > nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase에 로그인되지 않았습니다.
    echo 다음 명령어로 로그인하세요: firebase login
    pause
    exit /b 1
)

echo.
echo 3. 프로젝트 설정 확인 중...
firebase use mamama-f2a52

echo.
echo 4. 웹 앱 배포 중...
firebase deploy --only hosting

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo 배포 완료!
    echo 웹사이트: https://mamama-f2a52.web.app
    echo ========================================
) else (
    echo.
    echo 배포 실패! 오류를 확인하세요.
)

echo.
pause
