from app.db.base import Base
from sqlalchemy import Column, Integer, String, ForeignKey, timezone, DateTime

class WatchHistory(Base):
    __tablename__ = "watch_history"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=False)
    watched_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    progress = Column(Integer, nullable=True)  
    category = Column(String(50), nullable=True)  # 임시 필드
