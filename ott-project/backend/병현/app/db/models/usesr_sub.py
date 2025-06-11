from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime, timezone
from app.db.base import Base
from sqlalchemy.orm import relationship

class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, index=True)
    subscription_plan_id = Column(Integer, ForeignKey("subscription_plans.id")) 
    # plan_id: "어떤 구독권(플랜)에 가입할 것인지"를 고르는 ID
    start_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime(timezone=True))  # 구독 시작일 + duration_days로 계산해서 저장


    subscription = relationship("SubscriptionPlan", back_populates="users")

# 조금 더 고쳐야 할것.