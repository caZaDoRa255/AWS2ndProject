from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from app.contents import service
from app.models.contents import ContentCreate
from typing import List, Optional
from app.db.session import get_db  # DB 연결 의존성

router = APIRouter(prefix="/contents", tags=["Contents"])

# 검색
@router.get("/search", response_model=List[ContentCreate])
def search_contents(
    keyword: str = Query(..., description="검색 키워드"),
    db: Session = Depends(get_db)
):
    return service.search_by_keyword(db, keyword)

# 전체 콘텐츠 목록 조회
@router.get("/", response_model=List[ContentCreate])
def get_all_contents(category: Optional[str] = None, db: Session = Depends(get_db)):
    return service.get_all_contents(db, category)

# 콘텐츠 상세 조회
@router.get("/{content_id}", response_model=ContentCreate)
def get_content_by_id(content_id: int, db: Session = Depends(get_db)):
    content = service.get_content_by_id(db, content_id)
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    return content

# # ✅ 테스트용 콘텐츠 생성 API - 테스트 후 주석처리
# @router.post("/", response_model=ContentCreate)
# def create_content(content_data: ContentCreate, db: Session = Depends(get_db)):
#     return service.create_content(db, content_data)
