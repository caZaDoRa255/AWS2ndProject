from fastapi import APIRouter, Depends
from app.stream import service
from app.models.history import History
from typing import List

router = APIRouter(prefix="/history", tags=["History"])
#  APIRouter는 "API 경로 모듈을 따로 분리할 수 있게 해주는 도구

# ✅ 임시 user_id (로그인 연동 전), 로그인한 사용자만 접근 가능
def get_current_user_id() -> int:
    return 1  # 추후 JWT 토큰에서 추출로 교체 예정
# 로그인 기능 없이도 개발 & 테스트 계속 하려고 "user_id = 1" 임시 유저로 대체해놓은 함수
# 나중에 이렇게 바뀜 , 참고용(여기서 get_current_user()는 토큰에서 user_id 꺼내오는 함수)
# from fastapi import Depends
# from app.auth.utils import get_current_user

# @router.get("/")
# def get_watch_history(user: User = Depends(get_current_user)):
#     return service.get_history(user.id)

@router.post("/{content_id}", response_model=History)
def add_watch_history(content_id: int, user_id: int = Depends(get_current_user_id)):
    return service.add_history(user_id, content_id)

@router.get("/", response_model=List[History])
def get_watch_history(user_id: int = Depends(get_current_user_id)):
    return service.get_history(user_id)

# ✅ 이어보기 API 추가
@router.get("/continue", response_model=List[History])
def get_continue_watching(user_id: int = Depends(get_current_user_id)):
    return service.get_continue_watching(user_id)

# Depends()는 "이 파라미터는 다른 함수(또는 객체)에서 받아와" 라는 뜻
# 즉, 의존성 주입 (Dependency Injection) 기능

