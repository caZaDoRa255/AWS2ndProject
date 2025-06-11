from fastapi import APIRouter, Depends
from app.stream import service
from app.schemas.history import History
from typing import List

router = APIRouter(prefix="/history", tags=["History"])
#  APIRouter는 "API 경로 모듈을 따로 분리할 수 있게 해주는 도구

# ✅ 임시 user_id (로그인 연동 전)
def get_current_user_id() -> int:
    return 1  # 추후 JWT 토큰에서 추출로 교체 예정

@router.post("/{content_id}", response_model=History)
def add_watch_history(content_id: int, user_id: int = Depends(get_current_user_id)):
    return service.add_history(user_id, content_id)

@router.get("/", response_model=List[History])
def get_watch_history(user_id: int = Depends(get_current_user_id)):
    return service.get_history(user_id)

# Depends()는 "이 파라미터는 다른 함수(또는 객체)에서 받아와" 라는 뜻
# 즉, 의존성 주입 (Dependency Injection) 기능

