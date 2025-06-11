from typing import List
from datetime import datetime
from app.schemas.history import History

# ✅ 시청 기록 저장소 (user_id → 기록 목록)
HISTORY_DB: dict[int, List[History]] = {}

def add_history(user_id: int, content_id: int) -> History:
    record = History(user_id=user_id, content_id=content_id, watched_at=datetime.now(),category="sf" )
    if user_id not in HISTORY_DB:
        HISTORY_DB[user_id] = []
    HISTORY_DB[user_id].append(record)
    return record

def get_history(user_id: int) -> List[History]:
    return HISTORY_DB.get(user_id, [])

#9번 카테고리는 나중에 빼기