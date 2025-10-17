#!/bin/bash

echo "========================================"
echo "   마음일기장 Firebase Hosting 배포"
echo "========================================"
echo

echo "[1/4] Flutter Web 빌드 중..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "❌ Flutter 빌드 실패"
    exit 1
fi
echo "✅ Flutter 빌드 완료"

echo
echo "[2/4] Firebase Hosting 초기화 확인..."
if [ ! -f firebase.json ]; then
    echo "Firebase Hosting 초기화 중..."
    firebase init hosting
    echo "✅ Firebase Hosting 초기화 완료"
else
    echo "✅ Firebase Hosting 설정 파일 존재"
fi

echo
echo "[3/4] 빌드 파일 정리..."
if [ -d build/web ]; then
    echo "✅ 빌드 파일 준비 완료"
else
    echo "❌ 빌드 파일이 없습니다"
    exit 1
fi

echo
echo "[4/4] Firebase Hosting 배포 중..."
firebase deploy --only hosting
if [ $? -ne 0 ]; then
    echo "❌ Firebase 배포 실패"
    exit 1
fi

echo
echo "========================================"
echo "✅ 배포 완료!"
echo "========================================"
echo
echo "웹사이트 URL을 확인하려면 Firebase 콘솔을 방문하세요:"
echo "https://console.firebase.google.com/"
echo
