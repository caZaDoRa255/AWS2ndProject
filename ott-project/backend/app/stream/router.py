from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.models.history import History
from app.models.user import User
from app.auth.utils import get_current_user  # ✅ 로그인 연동된 유저 반환 함수
from app.db.session import get_db
from app.stream import service
from app.subscription.service import has_valid_subscription

import boto3
import os
import logging

router = APIRouter(prefix="/history", tags=["History"])

# 운영용

# S3 설정
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
BUCKET_NAME = "your-bucket-name"
REGION = "ap-northeast-2"

s3_client = boto3.client(
    's3',
    region_name=REGION,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY
)
# ✅ 로그 설정 (admin과 중복 설정은 없어도 됨, 단일 로깅 파일 공유)
logger = logging.getLogger(__name__)
# Python 로깅 시스템은 전역(global)으로 동작
# 즉, basicConfig()는 프로젝트 전체에 한 번만 설정하면 전체에 적용(꼭 한번만 작성해야함, 중복 작성 시 두번째 호출은 무시)


# 유저 스트리밍용 url
@router.get("/{content_id}/url")
def get_stream_url(
    content_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # ✅ 이용권 유효성 확인
    if not has_valid_subscription(user.id, db):
        raise HTTPException(status_code=403, detail="유효한 이용권이 없습니다.")

    # ✅ presigned URL 발급
    key = f"videos/{content_id}.mp4"
    try:
        url = s3_client.generate_presigned_url(
            ClientMethod='get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': key},
            ExpiresIn=3600  # 1시간 유효, 프론트에서 유효시간 지나면 자동으로 새로 발급받게 만들어야함
        )
        logger.info(f"[스트리밍 URL 발급] content_id={content_id}, user_id={user.id}")
        return {"stream_url": url}
    
    except Exception as e:
        logger.error(f"[스트리밍 URL 발급 실패] content_id={content_id}, user_id={user.id}, error={str(e)}")
        raise HTTPException(status_code=500, detail="영상 재생 URL 생성에 실패했습니다.")
    
# 시청 기록 저장
@router.post("/{content_id}", response_model=History)
def add_watch_history(
    content_id: int,
    progress: int = Query(0, ge=0, le=100),  # 진행률 쿼리 파라미터
    user: User = Depends(get_current_user),  # 🔑 로그인된 유저
    db: Session = Depends(get_db)            # DB 세션
):
    # 유효이용권인지 확인하고 영상재생
    if not has_valid_subscription(user.id, db):
        raise HTTPException(status_code=403, detail="이용권이 만료되었습니다.")
    
    return service.add_history(db, user.id, content_id, progress)

# 전체 시청 기록 조회
@router.get("/", response_model=List[History])
def get_watch_history(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return service.get_history(db, user.id)

# 이어보기 조회 (진행률 1~99%)
@router.get("/continue", response_model=List[History])
def get_continue_watching(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 눌렀을 때 영상 재생으로 연결될 수 있으므로 유효이용권확인
    if not has_valid_subscription(user.id, db):
        raise HTTPException(status_code=403, detail="이용권이 만료되었습니다.")
    
    return service.get_continue_watching(db, user.id)

# Depends()는 "이 파라미터는 다른 함수(또는 객체)에서 받아와" 라는 뜻
# 즉, 의존성 주입 (Dependency Injection) 기능


# 테스트용
# ✅ 시청 기록 저장 (테스트용)
# @router.post("/test/{content_id}", response_model=History)
# def test_add_watch_history(
#     content_id: int,
#     user_id: int = Query(...),
#     progress: int = Query(0, ge=0, le=100),
#     db: Session = Depends(get_db)
# ):
#     return service.add_history(db, user_id, content_id, progress)

# # ✅ 시청 기록 전체 조회 (테스트용)
# @router.get("/test/history", response_model=List[History])
# def test_get_watch_history(
#     user_id: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     return service.get_history(db, user_id)

# # ✅ 이어보기 조회 (테스트용)
# @router.get("/test/continue", response_model=List[History])
# def test_continue_watching(
#     user_id: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     return service.get_continue_watching(db, user_id)
