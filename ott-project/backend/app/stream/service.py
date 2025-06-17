from typing import List
from datetime import datetime
from app.models.history import History

# ✅ 시청 기록 저장소 (user_id → 기록 목록)
HISTORY_DB: dict[int, List[History]] = {}

def add_history(user_id: int, content_id: int, progress: int = 0) -> History:
    record = History(user_id=user_id, content_id=content_id, watched_at=datetime.now(),progress=progress,category="sf" )
    if user_id not in HISTORY_DB:
        HISTORY_DB[user_id] = []
    HISTORY_DB[user_id].append(record)
    return record

# 🔹 전체 시청 기록을 반환
def get_history(user_id: int) -> List[History]:
    return HISTORY_DB.get(user_id, [])

# 🔹 진행률 1~99%인 콘텐츠만 반환 (이어보기용)
def get_continue_watching(user_id: int) -> List[History]:
    history = HISTORY_DB.get(user_id, [])
    # 이어볼만한 콘텐츠만 필터링 (진행률 0% 초과, 100% 미만)
    return [h for h in history if h.progress and 0 < h.progress < 100]

# “이어보기” 기능 = 진행률(progress) 있는 시청기록만 필터링해서 보여주는 API
#9번째줄 카테고리는 나중에 빼기