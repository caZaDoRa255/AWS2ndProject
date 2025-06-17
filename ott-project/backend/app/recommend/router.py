from fastapi import APIRouter, Query
from app.recommend import service as recommend_service
from typing import Optional

router = APIRouter(
    prefix="/recommend",
    tags=["Recommend"]
)

@router.get("/")
def recommend(user_id: int = Query(..., description="추천 받을 사용자 ID"), limit: Optional[int] = 5):
    """
    시청 이력 기반 추천 콘텐츠 반환
    """
    return recommend_service.get_recommendations(user_id=user_id, limit=limit or 5)  # None이면 5로 대체

#recommend_service에서 
#def get_recommendations(user_id: int, limit: int = 5):  # ❌ limit은 int만 허용
# limit=None이 들어갈 수도 있다는 가능성 때문에 에러가 발생 -> or 5 추가해주기
