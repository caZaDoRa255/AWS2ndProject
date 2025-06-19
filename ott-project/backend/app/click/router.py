from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.click import ClickLogCreate, ClickLogResponse
from app.click import service
from app.auth.utils import get_current_user  # ← 로그인된 유저 가져오기

router = APIRouter()

# 운영용
@router.post("/click", response_model=ClickLogResponse)
def create_click_log(
    click_data: ClickLogCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    return service.log_click(db, current_user.id, click_data.content_id)

# 테스트용
# @router.post("/click/test", response_model=ClickLogResponse)
# def test_click_log(
#     content_id: int = Query(...),
#     user_id: int = Query(...),  # 🔹 토큰 없이 쿼리로 직접 user_id 받음
#     db: Session = Depends(get_db)
# ):
#     return service.log_click(db, user_id, content_id)