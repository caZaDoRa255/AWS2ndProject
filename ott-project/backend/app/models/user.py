from pydantic import BaseModel, EmailStr
# 📌 Python의 datetime, timezone 가져옴 (created_at에 사용됨)
from datetime import datetime, timezone
# 📌 SQLAlchemy 컬럼 타입 정의용
from sqlalchemy import Column, Integer, String, DateTime
from app.db.base import Base

# SQLAlchemy 모델
class User(Base):  # ← ✅ 이게 테이블 생성 기준!
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    nickname = Column(String(100))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

# Pydantic 모델
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nickname: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserInDB(BaseModel): #내부에서만 사용(DB 저장용 / 내부 처리용)
    id: int  #DB에서 자동으로 생성되는 숫자(PK) 
    email: EmailStr
    password_hash: str
    nickname: str
    created_at: datetime

    class Config:
        orm_mode = True  # SQLAlchemy 객체 -> Pydantic 모델 자동 매핑 허용

#✅ auth의 User.id → int인 이유
# DB에서 AUTO_INCREMENT로 관리하는 순번 ID
# 사용자 눈에는 안 보임 (백엔드 식별용)
# email, nickname이 진짜 사용자용 ID 역할을 함