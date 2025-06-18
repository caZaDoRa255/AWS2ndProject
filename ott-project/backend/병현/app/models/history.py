from pydantic import BaseModel
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Column, Integer, DateTime, String, ForeignKey
from app.db.base import Base

# 🔸 SQLAlchemy: DB 테이블용
class WatchHistory(Base):
    __tablename__ = "watch_history"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=False)
    watched_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    progress = Column(Integer, nullable=True)  
    category = Column(String(50), nullable=True)  # 임시 필드

# 🔸 Pydantic: API 요청/응답 검증용
class History(BaseModel):
    user_id: int
    content_id: int
    watched_at: datetime
    progress: Optional[int] = None  # 예: 0~100 (%), 이어보기용
    category: Optional[str] = None #임시 필드 (추천용 테스트), recommend/service 2번 작성때문에 추가

    class Config:
        orm_mode = True
