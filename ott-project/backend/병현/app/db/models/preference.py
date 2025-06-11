from app.db.base import Base
from sqlalchemy import Column, Integer, String, ForeignKey

class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    genre = Column(String(50), nullable=False)  # 장르 하나씩 저장
#     SQLAlchemy는 리스트(List[str])를 직접 컬럼에 못 넣어서, 장르마다 한 줄씩 저장해야 함
#      → 즉, "drama", "action" 같은 건 행을 여러 개로 나눠서 저장하는 구조