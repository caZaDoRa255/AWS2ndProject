from pydantic import BaseModel, EmailStr
from typing import Optional

#Python에서는 같은 파일 안에서 클래스를 타입 힌트로 쓸 때는 순서가 꽤 중요해 
# — 정확히 말하면, 클래스가 파싱될 때 참조하려는 이름이 이미 메모리에 올라와 있어야 되기 때문

# Python은 인터프리터 방식 → 위에서 아래로 순차 실행
# 그래서 UserProfile 클래스 안에서 Subscription을 쓰려면, Subscription이 먼저 정의돼 있어야 함

class Subscription(BaseModel):   #UserProfile보다 먼저 Subscription이 정의돼 있어야 함!
    name: str         # ex. "프리미엄", "베이직"
    expires_at: str   # ex. 만료일 "2025-06-30"

class UserProfile(BaseModel):
    id: int
    email: EmailStr
    nickname: str
    language: Optional[str] = None
    subscription: Optional[Subscription] = None

    class Config:
        orm_mode = True

class UserUpdate(BaseModel):
    nickname: Optional[str] = None
    language: Optional[str] = None

