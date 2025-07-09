from sqlalchemy.orm import Session
from app.models.favorites import Favorite
from app.models.favorites import FavoriteCreate
from fastapi import HTTPException
from typing import List
from app.models.contents import Content

# ✅ 찜 추가
def add_favorite(db: Session, user_id: int, content_id: int) -> FavoriteCreate:
    # 중복 확인
    favorite = db.query(Favorite).filter_by(user_id=user_id, content_id=content_id).first()
    if favorite:
        raise HTTPException(status_code=400, detail="이미 찜한 콘텐츠입니다.")

    new_favorite = Favorite(user_id=user_id, content_id=content_id)
    db.add(new_favorite)
    db.commit()
    db.refresh(new_favorite)

    # 🔍 콘텐츠 정보 가져오기 (title, image_url)
    content = db.query(Content).filter_by(id=content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="콘텐츠 정보를 찾을 수 없습니다.")

    # ✅ FavoriteCreate로 감싸서 리턴
    return FavoriteCreate(
        user_id=new_favorite.user_id,
        content_id=new_favorite.content_id,
        title=content.title,
        thumbnail_url=getattr(content, "thumbnail_url", "")  # 오류 방지용
    )

# ✅ 찜 삭제
def remove_favorite(db: Session, user_id: int, content_id: int) -> bool:
    favorite = db.query(Favorite).filter_by(user_id=user_id, content_id=content_id).first()
    if favorite:
        db.delete(favorite)
        db.commit()
        return True
    return False

# ✅ 찜 목록 조회 (프론트엔드에서 "내 찜 목록" 페이지를 만들 때 이 API를 부르면 됨)
def get_favorites(db: Session, user_id: int) -> List[FavoriteCreate]:
    favorites = db.query(Favorite).filter_by(user_id=user_id).all()
    result = []
    for fav in favorites:
        content = db.query(Content).filter_by(id=fav.content_id).first()
        if content:
            result.append(FavoriteCreate(
                user_id=user_id,
                content_id=content.id,
                title=content.title,
                thumbnail_url=getattr(content, "thumbnail_url", "")  # 👈 프론트에서 썸네일로 사용
            ))
    return result
# 이미지url이 빈칸일 경우 프론트가 고려해야할점! 
# 이미지가 빈칸일 경우 기본 이미지(예: "no-image.jpg")로 대체할 수 있도록 프론트에서 if 처리해주는 게 좋아.

# 썸네일클릭 -> 컨텐츠상세페이지 -> 찜하기 흐름으로? -> 이게 더 괜찮을수도 
# 썸네일에서 바로 찜하기 흐름으로? -> 이건 찜하고싶지않은데 보다가 잘못누를수있음