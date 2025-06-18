from fastapi import APIRouter, Depends, HTTPException,Query
from app.favorites import service
from app.models.favorites import FavoriteCreate
from app.auth.utils import get_current_user   
from sqlalchemy.orm import Session
from app.db.session import get_db
from typing import List

router = APIRouter(prefix="/favorites", tags=["Favorites"])

# 운영용
@router.post("/{content_id}", response_model=FavoriteCreate)
def add_favorite(content_id: int, 
                 user=Depends(get_current_user), 
                 db: Session = Depends(get_db)):
    return service.add_favorite(db, user.id, content_id)

@router.delete("/{content_id}")
def delete_favorite(content_id: int, 
                    user=Depends(get_current_user), 
                    db: Session = Depends(get_db)):
    success = service.remove_favorite(db, user.id, content_id)
    if not success:
        raise HTTPException(status_code=404, detail="Favorite not found")
    return {"detail": "찜 제거 완료"}

@router.get("/", response_model=List[FavoriteCreate])
def get_favorite_list(user=Depends(get_current_user), db: Session = Depends(get_db)):
    return service.get_favorites(db, user.id)


# 테스트용
# ✅ 찜 추가 (테스트용)
# @router.post("/test/{content_id}", response_model=FavoriteCreate)
# def test_add_favorite(
#     content_id: int,
#     user_id: int = Query(...),  # 👈 토큰 대신 user_id 직접 입력
#     db: Session = Depends(get_db)
# ):
#     return service.add_favorite(db, user_id, content_id)

# # ✅ 찜 삭제 (테스트용)
# @router.delete("/test/{content_id}")
# def test_delete_favorite(
#     content_id: int,
#     user_id: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     success = service.remove_favorite(db, user_id, content_id)
#     if not success:
#         raise HTTPException(status_code=404, detail="Favorite not found")
#     return {"detail": "찜 제거 완료"}

# # ✅ 찜 목록 조회 (테스트용)
# @router.get("/test/list", response_model=List[FavoriteCreate])
# def test_get_favorites(
#     user_id: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     return service.get_favorites(db, user_id)
