from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nickname: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserInDB(BaseModel):
    id: int  #DB에서 자동으로 생성되는 숫자(PK) 
    email: EmailStr
    password_hash: str
    nickname: str
    created_at: datetime

#✅ auth의 User.id → int인 이유
# DB에서 AUTO_INCREMENT로 관리하는 순번 ID
# 사용자 눈에는 안 보임 (백엔드 식별용)
# email, nickname이 진짜 사용자용 ID 역할을 함
