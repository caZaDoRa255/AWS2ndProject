from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import List
from app.models.history import History
from app.models.history import WatchHistory  # SQLAlchemy 모델
from app.contents.service import get_content_by_id
from fastapi import HTTPException
from app.models.contents import Content # SQLAlchemy 모델

# ✅ 시청 기록 추가 (DB 저장)
def add_history(db: Session, user_id: int, content_id: int, progress: int = 0) -> History:

    content = get_content_by_id(db, content_id)
    if not content:
        raise HTTPException(status_code=404, detail="콘텐츠를 찾을 수 없습니다.")
    
    record = WatchHistory(
        user_id=user_id,
        content_id=content_id,
        watched_at=datetime.now(timezone.utc),
        progress=progress,
        category=content.category  # 임시값 ,카테고리 컨텐츠에서 가져와야함
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return History.model_validate(record)

# ✅ 전체 시청 기록 조회
def get_history(db: Session, user_id: int) -> List[History]:
    records = db.query(WatchHistory).filter_by(user_id=user_id).all()
    result = []

    for r in records:
        content = db.query(Content).filter(Content.id == r.content_id).first()

        if not content:
            print(f"❗ 콘텐츠 {r.content_id}를 찾을 수 없습니다.")
            title = "제목 불러오기 실패"  # 또는 "알 수 없음", "정보 없음"
        else:
            title = content.title

        result.append(History(
            user_id=r.user_id,
            content_id=r.content_id,
            watched_at=r.watched_at,
            progress=r.progress,
            category=r.category,
            title=title  # 🔸 여기에 title 주입
        ))

    return result

# ✅ 이어보기: 진행률 1~99%
def get_continue_watching(db: Session, user_id: int) -> List[History]:
    records = db.query(WatchHistory).filter(
        WatchHistory.user_id == user_id,
        WatchHistory.progress > 0,
        WatchHistory.progress < 100
    ).all()
    return [History.model_validate(r) for r in records]

# 이어보기는 진행률 바 + 썸네일로 보여주고싶음 -> 타이틀 넣지않음 (쌈네일에 타이틀 나오니깐..?)

# “이어보기” 기능 = 진행률(progress) 있는 시청기록만 필터링해서 보여주는 API
# 넷플처럼 메인에 시청기록 나오도록 해주세요~!