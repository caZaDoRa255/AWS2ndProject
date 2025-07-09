from sqlalchemy.orm import Session
from app.models.contents import Content, ContentCreate


def create_content_record(db: Session, content_data: ContentCreate):
    db_content = Content(
        title=content_data.title,
        description=content_data.description,
        category=content_data.category,
        year=content_data.year,
        thumbnail_url=None # 초기에는 썸네일이 없으므로 None
    )
    db.add(db_content)
    db.commit()
    db.refresh(db_content)
    return db_content

def get_content_by_id(db: Session, content_id: int):
    # 이미지 콜백 처리에서 사용할 ID 조회 함수
    return db.query(Content).filter(Content.id == content_id).first()

def update_content_thumbnail(db: Session, content_id: int, thumbnail_url: str):
    db_content = db.query(Content).filter(Content.id == content_id).first()
    if db_content:
        db_content.thumbnail_url = thumbnail_url
        db.add(db_content)
        db.commit()
        db.refresh(db_content)
        return db_content
    return None


# app/contents/crud.py 파일을 만든 주된 이유는 
# 데이터베이스 상호작용 로직을 명확하게 분리하고, 프로젝트를 더욱 체계적으로 관리하기 위해
# CRUD (Create, Read, Update, Delete)는 
# 데이터베이스와 직접적으로 소통하며 데이터를 생성, 조회, 수정, 삭제하는 가장 기본적인 연산들을 의미
