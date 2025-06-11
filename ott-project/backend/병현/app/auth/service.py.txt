from app.models.user_profile import UserProfile, UserUpdate
from fastapi import HTTPException
from app.models.user_profile import Subscription


# 임시 더미 DB
fake_users_db = {
    1: {
        "id": 1,
        "email": "test@example.com",
        "nickname": "tester",
        "language": "ko"
    }
}

def get_user_profile(user_id: int) -> UserProfile:
    user = fake_users_db.get(user_id)
    if not user:
        raise ValueError("User not found")
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 임시 이용권 정보
    subscription = Subscription(
        name= "프리미엄",
        expires_at= "2025-06-30"
    )
    return UserProfile(**user,subscription=subscription)

def update_user_profile(user_id: int, update_data: UserUpdate) -> UserProfile:
    user = fake_users_db.get(user_id)
    if not user:
        raise ValueError("User not found")

    if update_data.nickname:
        user["nickname"] = update_data.nickname
    if update_data.language:
        user["language"] = update_data.language

    return UserProfile(**user)


