from app.db.base import Base
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

class SubscriptionPlan(Base):
    __tablename__ = "subscription_plans"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)              # ex. 프리미엄, 베이직등의 구독권(paln)저장
    description = Column(String, nullable=True)        # ex. 혜택 설명
    price = Column(Integer, nullable=False)            # 단위: 원
    duration_days = Column(Integer, nullable=False)    # ex. 30일

    users = relationship("UserProfileORM", back_populates="subscription")