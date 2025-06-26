from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.models.history import History
from app.models.user import User
from app.auth.utils import get_current_user  # ✅ 로그인 연동된 유저 반환 함수
from app.db.session import get_db
from app.stream import service
from app.subscription.service import has_valid_subscription

router = APIRouter(prefix="/history", tags=["History"])

# 운영용 - 실제 사용
# ✅ 시청 기록 저장
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

# ✅ 전체 시청 기록 조회
@router.get("/", response_model=List[History])
def get_watch_history(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return service.get_history(db, user.id)

# ✅ 이어보기 조회 (진행률 1~99%)
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


# 테스트하고 지우기 -주석처리함
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
