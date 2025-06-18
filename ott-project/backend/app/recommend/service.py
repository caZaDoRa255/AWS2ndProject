from app.stream import service as stream_service  # 시청 기록 모듈
from app.contents import service as contents_service  # 콘텐츠 목록 불러오기
import random
from typing import List, Dict
from app.models.contents import ContentCreate
from sqlalchemy.orm import Session

def get_recommendations(db: Session, user_id: int, limit: int = 5)-> List[ContentCreate]:
#  -> List[ContentCreate]는 꼭 필요한 건 아니지만:
# 함수의 반환 타입을 명확히 하려면 넣는 게 좋음
# 특히 **FastAPI나 IDE(Pylance 등)**에서 타입 추론, 자동완성, 오류 체크 등에 도움이 돼.
# 테스트 코드나 유지보수에도 이게 있으면 훨씬 안정적
# recommendations 리스트 안의 객체가 Content(SQLAlchemy ORM)
# 이걸 쓸거면 리턴에 ContentCreate.model_validate()로 변환해주기!
# SQLAlchemy 모델 → Pydantic 모델로 바꿔줌
# return recommendations 이렇게쓰면 오류-> 리턴 타입은 **ContentCreate (Pydantic 모델)**이기 때문

    # 1. 시청 기록 불러오기
    history = stream_service.get_history(db, user_id)

    if not history:
        return []  # 시청 기록 없으면 추천도 없음

    # 2. 최근 시청한 장르 뽑기 (마지막 3개)
    recent_categories = [record.category for record in history[-3:] if record.category] 

    # 3. DB에서 콘텐츠 전체 조회 (카테고리 필터링은 직접 적용)
    all_contents = contents_service.get_all_contents(db=db,category=None)
    candidates = [
        content for content in all_contents
        if any(cat.strip() in recent_categories for cat in content.category.split(","))
        # if content.category in recent_categories #"코미디,액션"  False 나올 수 있음
    ]

    # 4. 랜덤으로 추천 콘텐츠 선택
    recommendations = random.sample(candidates, min(limit, len(candidates)))

    return [ContentCreate.model_validate(c) for c in recommendations]

# 이건 추천 콘텐츠가 너무 많을 때, 그중 랜덤으로 limit개만 보여주기 위해서
# 예: 사용자가 drama 3개 봤는데, drama 콘텐츠가 50개면 → 랜덤 5개만 보여줌.
# 중복 안 나오게 하면서도, 추천이 매번 조금씩 다르게 보이도록 유도.
# 즉, 다양성 보장 + limit 개수 보장 목적.
