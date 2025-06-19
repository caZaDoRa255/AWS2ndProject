from pydantic import BaseModel, EmailStr
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Boolean # SQLAlchemy 컬럼 타입 정의용
from app.db.base import Base

class LoginRequest(BaseModel):  #운영자용
    email: str
    password: str

class TokenResponse(BaseModel):  #운영자용
    access_token: str 

# SQLAlchemy 모델
class User(Base):  # ← ✅ 이게 테이블 생성 기준!
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    nickname = Column(String(100))
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_admin = Column(Boolean, default=False)  # 🔹 운영자 여부
    # is_admin=True인 경우만 관리자 API 접근 허용 
    # (디비에 수동으로 작성해야함,관리자가 많아지면 관리자용 회원가입페이지 만들기 고민)
    # -- 운영자는 이렇게 명시적으로 True
    # INSERT INTO users (email, password_hash, is_admin) VALUES ('admin@example.com', '...', true);

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