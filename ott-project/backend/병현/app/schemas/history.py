from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class History(BaseModel):
    user_id: int
    content_id: int
    watched_at: datetime
    category: Optional[str] = None #임시 필드 (추천용 테스트), recommend/service 2번 작성때문에 추가

    class Config:
        orm_mode = True
