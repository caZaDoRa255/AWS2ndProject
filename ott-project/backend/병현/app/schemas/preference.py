from pydantic import BaseModel
from typing import List

class Preference(BaseModel):
    user_id: int
    genres: List[str]  # 예: ["drama", "action", "documentary"]

    class Config:
        orm_mode = True
