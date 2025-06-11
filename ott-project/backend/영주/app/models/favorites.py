from pydantic import BaseModel

class Favorite(BaseModel):
    user_id: int  #내부에서 쓰는 DB의 고유번호
    content_id: int

    class Config:
        orm_mode = True
