from fastapi import APIRouter, Depends, HTTPException
from app.favorites import service
from app.models.favorites import FavoriteCreate
from typing import List

router = APIRouter(prefix="/favorites", tags=["Favorites"])

# ✅ 임시 user_id (로그인 연동 전용 더미 값)
def get_current_user_id() -> int:
    return 1  # 로그인 연동 전이니까 임시로 user_id = 1 고정
              # 나중에 실제 인증 연결 시 JWT에서 user_id 추출
              # 추후 JWT 연동 시 이 부분만 바꾸면 전체 API는 그대로 유지됨

@router.post("/{content_id}", response_model=FavoriteCreate)
def add_favorite(content_id: int, user_id: int = Depends(get_current_user_id)):
    return service.add_favorite(user_id, content_id)

@router.delete("/{content_id}")
def delete_favorite(content_id: int, user_id: int = Depends(get_current_user_id)):
    success = service.remove_favorite(user_id, content_id)
    if not success:
        raise HTTPException(status_code=404, detail="Favorite not found")
    return {"detail": "Favorite removed"}

@router.get("/", response_model=List[FavoriteCreate])
def get_favorite_list(user_id: int = Depends(get_current_user_id)):
    return service.get_favorites(user_id)
