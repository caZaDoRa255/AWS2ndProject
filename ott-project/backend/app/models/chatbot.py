from sqlalchemy import Column, Integer, String, DateTime, func
from datetime import datetime
from pydantic import BaseModel
from app.db.base import Base

# 🔹 SQLAlchemy 모델
class ChatLog(Base):
    __tablename__ = "chat_logs"

    id = Column(Integer, primary_key=True)
    user_input = Column(String, nullable=False)
    gemini_response = Column(String, nullable=False)
    created_at = Column(DateTime, default=func.now())
    # 개인정보 보호문제로 익명으로 대화내용을 저장하기위해 유저아이디는 저장하지않음
    # 대화내용 저장 이유: 품질관리 & 문제 대응이 주 목적 

# 🔹 Pydantic 모델
class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    id: int
    user_input: str
    gemini_response: str
    created_at: datetime

    class Config:
        from_attributes = True
