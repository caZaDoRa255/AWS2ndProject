from app.db.base import Base
from sqlalchemy import Column, Integer, String, ForeignKey


class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)  # PK 추가해도 되고 생략도 가능
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=False)
