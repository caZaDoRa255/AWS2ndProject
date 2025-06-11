from sqlalchemy import Column, Integer, String
from app.db.base import Base


class Content(Base):
    __tablename__ = "contents"  # 실제 DB 테이블명
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(String(500))
    category = Column(String(100))
    year = Column(Integer)