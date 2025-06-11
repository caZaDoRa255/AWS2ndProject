from typing import List, Optional
from app.models.contents import Content
from typing import List, Dict

# 💡 지금은 더미 콘텐츠 데이터 사용 중 (나중에 DB로 교체 가능)
FAKE_CONTENT_DB = [
    Content(id=1, title="Inception", description="Dream within a dream", category="sf", year=2010),
    Content(id=2, title="Parasite", description="Social satire", category="drama", year=2019),
    Content(id=3, title="Interstellar", description="Space adventure", category="sf", year=2014),
    Content(id=4, title="The Glory", description="Revenge drama", category="drama", year=2023),
]

def get_all_contents(category: Optional[str] = None) -> List[Content]:
    if category:
        return [content for content in FAKE_CONTENT_DB if content.category == category]
    return FAKE_CONTENT_DB

def get_content_by_id(content_id: int) -> Optional[Content]:
    for content in FAKE_CONTENT_DB:
        if content.id == content_id:
            return content
    return None

# 나중에 db로 교체 시 
#  1.모델에 파일만들기: models/orm/content_orm.py 만들기 → SQLAlchemy ORM 클래스 정의
#  2.service.py에서 더미 리스트 제거 → DB 쿼리로 대체
#  3.router.py에서 db: Session = Depends(get_db) 추가

#타입힌트
# recommend에서 3번 작성 할 때 ,
# contents_service.contents는 그냥 리스트(List[dict]) 같은 변수인데,
# Python에서 동적으로 정의된 변수는 **정적 타입 분석기(Pylance 등)**가 정확히 추적 못해서
# contents/service에 타입 힌트 추가하면 빨간줄 사라짐! (Python이 "이건 리스트임!" 하고 알려주는 셈)
contents: List[Dict] = [
    {
        "id": 1,
        "title": "The Matrix",
        "category": "sf",
        "year": 1999,
        "description": "A computer hacker learns about the true nature of reality."
    },
    {
        "id": 2,
        "title": "The Godfather",
        "category": "drama",
        "year": 1972,
        "description": "The aging patriarch of an organized crime dynasty transfers control to his reluctant son."
    },
    # ... 추가 데이터
]