from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime, date, timezone
from typing import Optional
from pydantic import BaseModel
from app.db.base import Base  
from sqlalchemy.orm import relationship #추가

# 🔹 1. 관리자용 DB 테이블 - 구독권 정의
class SubscriptionPlan(Base):
    __tablename__ = "subscription_plans"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)              # ex. 프리미엄, 베이직등의 구독권(paln)저장
    description = Column(String, nullable=True)        # ex. 혜택 설명
    price = Column(Integer, nullable=False)            # 단위: 원
    duration_days = Column(Integer, nullable=False)    # ex. 30일

# 🔹 2. 유저용 DB 테이블 - 유저가 선택한 구독권 내역
class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, index=True)
    subscription_plan_id = Column(Integer, ForeignKey("subscription_plans.id")) 
    # plan_id: "어떤 구독권(플랜)에 가입할 것인지"를 고르는 ID
    start_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime(timezone=True))  # 구독 시작일 + duration_days로 계산해서 저장

    subscription_plan = relationship("SubscriptionPlan")  # ✅ 추가(subscription_plan 접근용)

# 🔹 3. API 응답용 Pydantic 모델 - 유저 프로필에서 subscription 필드로 사용
class Subscription(BaseModel):
    name: str                    # ex. "프리미엄"
    expires_at: Optional[date] = None  # ex. 2025-06-30

    class Config:
        orm_mode = True
        exclude_none = True #이게 있어야 만료일 none일때 null안뜸
        
#테스트용(구독권저장)
# class SubscriptionPlanOut(BaseModel):
#     id: int
#     name: str
#     price: int
#     duration_days: int

#     class Config:
#         from_attributes = True  # ✅ Pydantic v2에서 orm_mode 대체