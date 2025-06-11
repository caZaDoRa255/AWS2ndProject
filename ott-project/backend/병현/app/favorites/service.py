from typing import List
from app.schemas.favorites import Favorite

# ✅ 임시 찜 저장소 (user_id → content_id 목록)
FAVORITE_DB: dict[int, set[int]] = {}

def add_favorite(user_id: int, content_id: int) -> Favorite:
    if user_id not in FAVORITE_DB:
        FAVORITE_DB[user_id] = set()
    FAVORITE_DB[user_id].add(content_id)
    return Favorite(user_id=user_id, content_id=content_id)

def remove_favorite(user_id: int, content_id: int) -> bool:
    if user_id in FAVORITE_DB and content_id in FAVORITE_DB[user_id]:
        FAVORITE_DB[user_id].remove(content_id)
        return True
    return False

def get_favorites(user_id: int) -> List[Favorite]:  #찜목록반환
    content_ids = FAVORITE_DB.get(user_id, set())
    return [Favorite(user_id=user_id, content_id=cid) for cid in content_ids]


# FAVORITE_DB는 임시 메모리 저장소야
# 실제 서비스에선 → DB에 favorites 테이블로 대체될 예정
# set()을 사용해서 중복 찜 방지
# 반환값은 모두 Favorite 모델로 구성됨
# CRD 있네요!