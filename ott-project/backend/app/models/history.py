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
    title: Optional[str] = None  # 🔸 타이틀 추가(sql모델에는 추가x)
    # 중복 데이터 저장은 지양하는 게 정석
    # 데이터가 한 군데만 바뀌면 되는데,두 군데 다 바뀌어야 하면 불일치 문제 발생 위험 있음.
    # 지금 구조 (조인 방식): 자동 반영됨 

    
# (Pydantic v2 스타일)
    model_config = {
        "from_attributes": True
    }
# Pydantic v1 스타일)
    # class Config:
    #     orm_mode = True
    
