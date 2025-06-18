from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.contents import Content  # SQLAlchemy ORM 모델
from app.models.contents import ContentCreate  # Pydantic 응답용
from sqlalchemy import or_, func


#  검색
def search_by_keyword(db: Session, keyword: str) -> List[ContentCreate]:
    keyword = keyword.strip().replace(" ", "")  # 여기서 직접 처리
    pattern = f"%{keyword.lower()}%"

    results = db.query(Content).filter(
        or_(
            func.replace(func.lower(Content.title), " ", "").like(func.lower(pattern)),
            func.replace(func.lower(Content.category), " ", "").like(func.lower(pattern))
        )
    ).all()

    # 🔍 디버깅용 출력
    # for c in results:
    #     print(f"[{c.category}] → 드라마 in? {'드라마' in c.category}")

    return [ContentCreate.model_validate(r) for r in results]



# ✅ 전체 콘텐츠 목록 조회
def get_all_contents(db: Session, category: Optional[str] = None) -> List[Content]:
    query = db.query(Content)
    if category:
        query = query.filter(func.lower(Content.category).like(f"%{category.lower()}%"))  # 부분 포함 검색
    return query.all()

# ✅ 콘텐츠 상세정보 조회
def get_content_by_id(db: Session, content_id: int) -> Optional[Content]:
    return db.query(Content).filter(Content.id == content_id).first()
# 상세조회(클릭 후 보는 세부 정보)는 검색(찾기 위한 것)이랑은 다름
# 유저가 검색 결과에서 썸네일을 클릭하거나
# 추천/이어보기 리스트에서 특정 콘텐츠를 클릭했을 때
# 해당 콘텐츠의 상세 정보를 보여주는 API

# # ✅ 콘텐츠 생성 (테스트용) -테스트 후 주석처리
# def create_content(db: Session, content_data: ContentCreate) -> Content:
#     # 🔸 카테고리 공백 제거 처리 -> 운영자 페이지에도 넣어야함!!
#     cleaned_category = ",".join([c.strip() for c in content_data.category.split(",")])
#     content = Content(**{**content_data.model_dump(), "category": cleaned_category})
#     # content = Content(**content_data.model_dump())
#     db.add(content)
#     db.commit()
#     db.refresh(content)
#     return content

#model_dump()는 dict()랑 동일한 역할을 하지만, Pydantic v2 표준 방식 

# 나중에 db로 교체 시 
#  1.모델에 파일만들기: models/orm/content_orm.py 만들기 → SQLAlchemy ORM 클래스 정의
#  2.service.py에서 더미 리스트 제거 → DB 쿼리로 대체
#  3.router.py에서 db: Session = Depends(get_db) 추가

#타입힌트
# recommend에서 3번 작성 할 때 ,
# contents_service.contents는 그냥 리스트(List[dict]) 같은 변수인데,
# Python에서 동적으로 정의된 변수는 **정적 타입 분석기(Pylance 등)**가 정확히 추적 못해서
# contents/service에 타입 힌트 추가하면 빨간줄 사라짐! (Python이 "이건 리스트임!" 하고 알려주는 셈)
# contents: List[Dict] = [
#     {
#         "id": 1,
#         "title": "The Matrix",
#         "category": "sf",
#         "year": 1999,
#         "description": "A computer hacker learns about the true nature of reality."
#     },
#     {
#         "id": 2,
#         "title": "The Godfather",
#         "category": "drama",
#         "year": 1972,
#         "description": "The aging patriarch of an organized crime dynasty transfers control to his reluctant son."
#     },
#     # ... 추가 데이터
# ]