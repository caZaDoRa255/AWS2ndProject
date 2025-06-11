from fastapi import APIRouter, HTTPException
from app.contents import service
from app.models.contents import Content
from typing import List
from typing import Optional

router = APIRouter(prefix="/contents", tags=["Contents"])

@router.get("/", response_model=List[Content])
def get_all_contents(category: Optional[str] = None):  #Optional[str]은 "str 또는 None일 수 있음"을 의미
    return service.get_all_contents(category)

@router.get("/{content_id}", response_model=Content)
def get_content_by_id(content_id: int):
    content = service.get_content_by_id(content_id)
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    return content
