from pydantic import BaseModel
from sqlalchemy import Column, Integer, String
from app.db.base import Base

# 🔸 SQLAlchemy: DB 테이블용
class Content(Base):
    __tablename__ = "contents"  # 실제 DB 테이블명
    id = Column(Integer, primary_key=True)
    title = Column(String(255), nullable=False)
    description = Column(String(500))
    category = Column(String(100))
    year = Column(Integer)

# 🔸 Pydantic: API 요청/응답 검증용
class ContentCreate(BaseModel):
    id: int #필요하면 str로 바꾸면된다
    title: str
    description: str
    category: str
    year: int

    class Config:
        orm_mode = True #Pydantic 모델이 ORM 객체(DB 객체)를 받아들일 수 있게 해주는 설정
        #기본적으로 Pydantic(BaseModel)은 dict만 인식
        #이걸 설정해두면 Pydantic이 DB ORM 객체(예:<User(id=1, email='abc@example.com')>)를 받아서 자동으로 dict처럼 변환
        #dict는 파이썬에서 가장 자주 쓰는 "딕셔너리 자료형", 즉 Key-Value(키-값) 구조, 예: {"id": 1}

# id int? str?
# int: 내부 식별용, DB 자동 생성, 지금은 이거로 OK,  
# str: 외부 API 연동이나 규칙 있는 ID가 필요한 경우 나중에 고려

# Q. 콘텐츠 ID를 그냥 숫자로만 순서대로 붙여도 될까?
#    아니면 drama1, sport1 같이 카테고리 기반 문자열로 붙이는 게 좋을까?
# A. ID는 식별자이지 의미가 없어야 가장 좋음
# why? 
# 1.변경에 강하다(숫자는 고정값이니까 어떤 정보가 바뀌어도 그대로 유지 가능) 예:카테고리추가,변경시
# 2.데이터 무결성 / 참조가 쉬움
#   -외래키(Foreign Key) 관계 설정할 때 id=12 같은 숫자가 훨씬 간편
#   -속도도 빠르고 인덱싱도 효율적
# 3.카테고리는 별도 컬럼에서 관리하면 됨(id는 단순히 생성 순서로 증가만 해주면 OK)