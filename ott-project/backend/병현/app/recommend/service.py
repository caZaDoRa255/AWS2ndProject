from app.stream import service as stream_service  # 시청 기록 모듈
from app.contents import service as contents_service  # 콘텐츠 목록 불러오기
import random
from typing import List, Dict

def get_recommendations(user_id: int, limit: int = 5):
    # 1. 시청 기록 불러오기
    history = stream_service.get_history(user_id)

    if not history:
        return []  # 시청 기록 없으면 추천도 없음

    # 2. 최근 시청한 장르 뽑기 (마지막 3개)
    recent_categories = [record.category for record in history[-3:]] #history에 카테고리 추가함

    # 3. 콘텐츠 중 해당 장르 포함된 것만 필터링
    candidates = [
        content for content in contents_service.contents #contents/service에 타입힌트 추가함
        if content["category"] in recent_categories
    ]

    # 4. 랜덤으로 추천 콘텐츠 선택
    recommendations = random.sample(candidates, min(limit, len(candidates)))

    return recommendations
