from sqlalchemy.orm import Session
from app.models.preference import Preference  # Pydantic 모델
from app.models.preference import UserPreference     # SQLAlchemy 모델
from typing import Optional

# 🔸 선호도 저장 (덮어쓰기)
def save_preference(db: Session, user_id: int, genres: list[str]) -> Preference:
    # 기존 선호도 모두 삭제
    db.query(UserPreference).filter_by(user_id=user_id).delete()

    # 새로운 장르 저장
    for genre in genres:
        db.add(UserPreference(user_id=user_id, genre=genre))

    db.commit()
    return Preference(user_id=user_id, genres=genres)

# 🔸 선호도 조회
def get_preference(db: Session, user_id: int) -> Optional[Preference]:
    result = db.query(UserPreference).filter_by(user_id=user_id).all()
    genres = [row.genre for row in result]
    return Preference(user_id=user_id, genres=genres) if genres else None


