from pydantic import BaseModel
from sqlalchemy import Column, Integer, ForeignKey
from app.db.base import Base

# 🔸 SQLAlchemy 모델 (DB 테이블용)
class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True)  
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=False)

    # Column : DB 테이블의 하나의 "열(컬럼)"을 정의 (이게 실제로 CREATE TABLE에서 column_name)
    # Integer : 해당 컬럼의 데이터 타입이 "정수"라는 뜻 (String, Boolean, DateTime 등 다른 타입들도 있음)
    # ForeignKey : 외래 키 제약조건(FK)**을 설정할 때 씀, 
    # "users.id"는 users 테이블의 id를 참조하겠다는 의미 (이렇게 하면 관계형 DB에서 JOIN이나 무결성 체크 가능!)

# 🔸 Pydantic 모델 (API 요청/응답용)
class FavoriteCreate(BaseModel):
    user_id: int  #내부에서 쓰는 DB의 고유번호
    content_id: int

    class Config:
        orm_mode = True
