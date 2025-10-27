# 마음일기장 Firebase 배포 스크립트 (PowerShell)

Write-Host "========================================" -ForegroundColor Green
Write-Host "마음일기장 Firebase 배포 스크립트" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "1. Firebase CLI 설치 확인 중..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "Firebase CLI 버전: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "Firebase CLI가 설치되지 않았습니다." -ForegroundColor Red
    Write-Host "다음 명령어로 설치하세요: npm install -g firebase-tools" -ForegroundColor Yellow
    Read-Host "Enter를 눌러 종료"
    exit 1
}

Write-Host ""
Write-Host "2. Firebase 로그인 상태 확인 중..." -ForegroundColor Yellow
try {
    firebase projects:list | Out-Null
    Write-Host "Firebase 로그인 상태: 정상" -ForegroundColor Green
} catch {
    Write-Host "Firebase에 로그인되지 않았습니다." -ForegroundColor Red
    Write-Host "다음 명령어로 로그인하세요: firebase login" -ForegroundColor Yellow
    Read-Host "Enter를 눌러 종료"
    exit 1
}

Write-Host ""
Write-Host "3. 프로젝트 설정 확인 중..." -ForegroundColor Yellow
firebase use mamama-f2a52

Write-Host ""
Write-Host "4. 웹 앱 배포 중..." -ForegroundColor Yellow
$deployResult = firebase deploy --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "배포 완료!" -ForegroundColor Green
    Write-Host "웹사이트: https://mamama-f2a52.web.app" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "배포 실패! 오류를 확인하세요." -ForegroundColor Red
}

Write-Host ""
Read-Host "Enter를 눌러 종료"
