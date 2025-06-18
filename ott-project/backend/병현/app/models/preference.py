from pydantic import BaseModel
from typing import List
from sqlalchemy import Column, Integer, String, ForeignKey
# from sqlalchemy.orm import relationship # 당장은 필수 아니고, API 연결 잘 되면 나중에
from app.db.base import Base

# 🔸 SQLAlchemy: DB 테이블용
class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    genre = Column(String(50), nullable=False)  # 장르 하나씩 저장
#     SQLAlchemy는 리스트(List[str])를 직접 컬럼에 못 넣어서, 장르마다 한 줄씩 저장해야 함
#      → 즉, "drama", "action" 같은 건 행을 여러 개로 나눠서 저장하는 구조

# 🔸 Pydantic: API 요청/응답 검증용
class Preference(BaseModel):
    user_id: int
    genres: List[str]  # 예: ["drama", "action", "documentary"]

    class Config:
        orm_mode = True
