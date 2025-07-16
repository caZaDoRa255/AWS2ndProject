#!/bin/bash

echo "🔍 애플리케이션 통신 확인 중..."

# Backend API 상태 확인
echo "📡 Backend API 상태 확인:"
curl -f https://api.moodlyharbor.click/health || echo "❌ Backend API 연결 실패"

# Frontend 접속 확인
echo "🌐 Frontend 접속 확인:"
curl -f https://frontend.moodlyharbor.link || echo "❌ Frontend 연결 실패"

# 데이터베이스 연결 확인
echo "🗄️ 데이터베이스 연결 확인:"
curl -f https://api.moodlyharbor.click/db/health || echo "❌ 데이터베이스 연결 실패"

# VPN을 통한 GCP FastAPI 연결 확인
echo "🔗 VPN을 통한 GCP FastAPI 연결 확인:"
curl -f http://34.55.195.186:8000/health || echo "❌ GCP FastAPI 연결 실패"

echo "✅ 애플리케이션 통신 확인 완료!" 