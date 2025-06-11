# app/preferences/router.py
from fastapi import APIRouter
from app.preferences import service
from app.schemas.preference import Preference

router = APIRouter(prefix="/users", tags=["Preferences"])

#장르 저장
@router.post("/{user_id}/preferences", response_model=Preference)
def set_user_preference(user_id: int, preference: Preference):
    return service.save_preference(user_id, preference.genres)

# 장르 조회
@router.get("/{user_id}/preferences", response_model=Preference)
def get_user_preference(user_id: int):
    pref = service.get_preference(user_id)
    if pref is None:
        return {"user_id": user_id, "genres": []}
    return pref
