from sqlalchemy import Column, Integer, ForeignKey, DateTime, func
from app.db.base import Base
from pydantic import BaseModel
from datetime import datetime

# 🔹 SQLAlchemy 모델
class ClickLog(Base):
    __tablename__ = "click_logs"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=False)
    clicked_at = Column(DateTime, default=func.now())

# 🔹 Pydantic 모델
class ClickLogCreate(BaseModel):
    content_id: int

class ClickLogResponse(BaseModel):
    id: int
    user_id: int
    content_id: int
    clicked_at: datetime

    class Config:
        orm_mode = True

# 지금까지는 요청,응답이 같아서 같이 썼지만 클릭로그는 요청,응답이 달라서 따로 작성하는게 좋음