from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.preference import Preference
from app.preferences import service
from app.db.session import get_db  

router = APIRouter(prefix="/users", tags=["Preferences"])

# 🔸 선호도 저장 (덮어쓰기 방식)
@router.post("/{user_id}/preferences", response_model=Preference)
def set_user_preference(user_id: int, preference: Preference, db: Session = Depends(get_db)):
    return service.save_preference(db, user_id, preference.genres)

# 🔸 선호도 조회
@router.get("/{user_id}/preferences", response_model=Preference)
def get_user_preference(user_id: int, db: Session = Depends(get_db)):
    pref = service.get_preference(db, user_id)
    return pref or Preference(user_id=user_id, genres=[])

# ✅ 이렇게 하면 이제:
# 회원가입 후 프론트에서 체크박스 선택 → POST로 저장
# “내 정보 보기” 화면에서 → GET으로 조회

# 유저프로필py 확인하면 preferences: List[str] = [] #선호도가 없을 경우에는 빈 배열로 반환됨 이게 있는데
# ★빈 배열로 반환되는걸 프론트에서 
# if (preferences.length === 0) {
#     return "선호 장르 없음"
# }  이렇게 나오게 부탁해요~!
#회원가입 선호장르 선택하는 부분에 '없음'항목도 만들기★