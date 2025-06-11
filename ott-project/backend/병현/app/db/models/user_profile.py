from app.db.base import Base
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship



class UserProfileORM(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    nickname = Column(String(100), nullable=False)
    language = Column(String(50), nullable=True)
    subscription_id = Column(Integer, ForeignKey("subscription_plans.id"), nullable=True)


    subscription = relationship("SubscriptionPlan", back_populates="users")