# app/preferences/service.py
from typing import Optional
from app.models.preference import Preference

# ✅ 더미 DB: user_id → Preference
PREFERENCE_DB: dict[int, Preference] = {}

def save_preference(user_id: int, genres: list[str]) -> Preference:
    pref = Preference(user_id=user_id, genres=genres)
    PREFERENCE_DB[user_id] = pref
    return pref

def get_preference(user_id: int) -> Optional[Preference]:
    return PREFERENCE_DB.get(user_id)

#회원가입 선호장르 선택하는 부분에 '없음'항목도 만들기