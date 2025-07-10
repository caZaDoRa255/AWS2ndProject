# GCP Firestore 설정 가이드

이 문서는 GCP Firestore 데이터베이스를 Terraform으로 설정하고 사용하는 방법을 설명합니다.

## 📋 목차

1. [개요](#개요)
2. [설정 파일](#설정-파일)
3. [배포 방법](#배포-방법)
4. [사용법](#사용법)
5. [보안 규칙](#보안-규칙)
6. [인덱스](#인덱스)

## 🎯 개요

Firestore는 Google Cloud의 NoSQL 문서 데이터베이스입니다. 이 설정은 OTT 프로젝트에 필요한 다음 기능들을 포함합니다:

- 사용자 관리
- 콘텐츠 관리
- 채팅 로그
- 클릭 로그
- 사용자 선호도
- 구독 관리
- 즐겨찾기

## 📁 설정 파일

### 1. firestore.tf
Firestore 데이터베이스와 관련 리소스를 정의합니다:

- `google_firestore_database`: 메인 데이터베이스
- `google_firestore_index`: 성능 최적화를 위한 인덱스들
- `google_firestore_document`: 보안 규칙

### 2. firestore_client_example.py
Firestore와 상호작용하는 Python 클라이언트 예제 코드입니다.

## 🚀 배포 방법

### 1. Terraform 초기화
```bash
cd infra/gcp/terraform
terraform init
```

### 2. 계획 확인
```bash
terraform plan
```

### 3. 배포 실행
```bash
terraform apply
```

### 4. 출력 확인
```bash
terraform output
```

## 💻 사용법

### Python 클라이언트 설정

1. **서비스 계정 키 생성**
   - GCP 콘솔에서 서비스 계정 생성
   - Firestore Admin 권한 부여
   - JSON 키 파일 다운로드

2. **환경 설정**
```python
import firebase_admin
from firebase_admin import credentials, firestore

# 서비스 계정 키 파일 경로 설정
cred = credentials.Certificate("path/to/service-account-key.json")
firebase_admin.initialize_app(cred, {
    'projectId': 'ott-project-462006'
})

db = firestore.client()
```

### 기본 CRUD 작업

#### 사용자 추가
```python
user_data = {
    'email': 'user@example.com',
    'name': '홍길동',
    'age': 30,
    'is_admin': False
}
db.collection('users').document('user123').set(user_data)
```

#### 사용자 조회
```python
doc = db.collection('users').document('user123').get()
if doc.exists:
    user = doc.to_dict()
    print(user)
```

#### 콘텐츠 추가
```python
content_data = {
    'title': '샘플 콘텐츠',
    'description': '이것은 샘플 콘텐츠입니다.',
    'category': 'movie',
    'duration': 120,
    'rating': 4.5
}
db.collection('contents').document('content123').set(content_data)
```

#### 카테고리별 콘텐츠 조회
```python
docs = db.collection('contents').where('category', '==', 'movie').stream()
for doc in docs:
    print(doc.to_dict())
```

## 🔒 보안 규칙

Firestore 보안 규칙은 다음과 같이 설정됩니다:

### 사용자 문서
- 본인만 읽기/쓰기 가능
- 관리자는 모든 사용자 읽기 가능

### 콘텐츠 문서
- 모든 사용자가 읽기 가능
- 관리자만 쓰기 가능

### 로그 문서
- 인증된 사용자만 읽기/쓰기 가능

### 선호도 문서
- 본인만 읽기/쓰기 가능

## 📊 인덱스

성능 최적화를 위해 다음 인덱스들이 설정됩니다:

### 사용자 인덱스
- `email` (오름차순)
- `created_at` (내림차순)

### 콘텐츠 인덱스
- `category` (오름차순)
- `created_at` (내림차순)

### 채팅 로그 인덱스
- `user_id` (오름차순)
- `timestamp` (내림차순)

### 클릭 로그 인덱스
- `user_id` (오름차순)
- `content_id` (오름차순)
- `timestamp` (내림차순)

## 📝 컬렉션 구조

### users
```
{
  "user_id": {
    "email": "user@example.com",
    "name": "홍길동",
    "age": 30,
    "is_admin": false,
    "created_at": timestamp,
    "updated_at": timestamp
  }
}
```

### contents
```
{
  "content_id": {
    "title": "콘텐츠 제목",
    "description": "콘텐츠 설명",
    "category": "movie",
    "duration": 120,
    "rating": 4.5,
    "created_at": timestamp,
    "updated_at": timestamp
  }
}
```

### chatlogs
```
{
  "log_id": {
    "user_id": "user123",
    "message": "사용자 메시지",
    "response": "챗봇 응답",
    "timestamp": timestamp
  }
}
```

### clicklogs
```
{
  "log_id": {
    "user_id": "user123",
    "content_id": "content123",
    "action_type": "view",
    "timestamp": timestamp
  }
}
```

### preferences
```
{
  "user_id": {
    "favorite_genres": ["action", "comedy"],
    "preferred_language": "ko",
    "auto_play": true,
    "updated_at": timestamp
  }
}
```

### subscriptions
```
{
  "subscription_id": {
    "user_id": "user123",
    "plan": "premium",
    "status": "active",
    "start_date": timestamp,
    "end_date": timestamp,
    "created_at": timestamp,
    "updated_at": timestamp
  }
}
```

### favorites
```
{
  "favorite_id": {
    "user_id": "user123",
    "content_id": "content123",
    "created_at": timestamp
  }
}
```

## 🔧 문제 해결

### 일반적인 문제들

1. **권한 오류**
   - 서비스 계정에 적절한 권한이 있는지 확인
   - Firestore Admin 역할이 부여되었는지 확인

2. **인덱스 오류**
   - 복합 쿼리에 대한 인덱스가 생성되었는지 확인
   - Firestore 콘솔에서 인덱스 상태 확인

3. **연결 오류**
   - 서비스 계정 키 파일 경로 확인
   - 프로젝트 ID가 올바른지 확인

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. GCP 콘솔의 Firestore 섹션
2. Terraform 상태 확인: `terraform show`
3. 로그 확인: `terraform logs`

## 📚 추가 자료

- [Firestore 공식 문서](https://firebase.google.com/docs/firestore)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Terraform Firestore Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database) 