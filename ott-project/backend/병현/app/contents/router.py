from fastapi import APIRouter, HTTPException
from app.contents import service
from app.schemas.contents import Content
from typing import List
from typing import Optional

router = APIRouter(prefix="/contents", tags=["Contents"])


@router.post("/seed")
def seed_fake_contents():
    service.seed_fake_contents()
    return {"msg": "더미 콘텐츠 10개 삽입 완료"}

@router.get("/", response_model=List[Content])
def get_all_contents(category: Optional[str] = None):  #Optional[str]은 "str 또는 None일 수 있음"을 의미
    return service.get_all_contents(category)

@router.get("/{content_id}", response_model=Content)
def get_content_by_id(content_id: int):
    content = service.get_content_by_id(content_id)
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    return content
