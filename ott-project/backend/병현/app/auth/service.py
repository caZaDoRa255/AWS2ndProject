from fastapi import HTTPException
from fastapi.responses import JSONResponse
from app.schemas.user import UserCreate, UserLogin
from app.schemas.user_profile import UserProfile, UserUpdate, Subscription
from app.auth.utils import hash_password, verify_password, create_access_token, create_refresh_token
from sqlalchemy.orm import Session
from app.db.models.user import User
from app.db.session import SessionLocal
# 임시 DB
# fake_users_db = {
#     1: {
#         "id": 1,
#         "email": "test@example.com",
#         "password_hash": hash_password("test1234"),
#         "nickname": "테스터",
#         "language": "ko",
#         "name": "프리미엄",
#         "expires_at": "2025-06-30"
#     }
# }

def signup(user: UserCreate):
    db: Session = SessionLocal()

    # 이메일 중복 확인
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")

    # 비밀번호 해싱 후 User 객체 생성
    hashed_pw = hash_password(user.password)
    new_user = User(
        email=user.email,
        password_hash=hashed_pw,
        nickname=user.nickname
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)  # 새로 생성된 user 객체 최신화 (id 포함)

    return {"msg": "회원가입 완료", "user_id": new_user.id}
#---------------------------

def login(user: UserLogin):
    db: Session = SessionLocal()

    # 이메일로 사용자 조회
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user:
        raise HTTPException(status_code=401, detail="존재하지 않는 이메일입니다.")

    # 비밀번호 검증
    if not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="비밀번호가 일치하지 않습니다.")

    # 토큰 발급
    access_token = create_access_token(data={"sub": db_user.email})
    refresh_token = create_refresh_token(data={"sub": db_user.email})

    # 응답 구성 (Refresh Token은 HttpOnly 쿠키로 설정)
    response = JSONResponse(content={"access_token": access_token, "token_type": "bearer"})
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        max_age=30 * 24 * 60 * 60,
        expires=30 * 24 * 60 * 60,
        path="/",
        samesite="lax",
        secure=False
    )

    return response

def get_user(user_id: int):
    db: Session = SessionLocal()

    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="해당 사용자를 찾을 수 없습니다.")

    return {
        "id": user.id,
        "email": user.email,
        "nickname": user.nickname,
        "created_at": user.created_at
    }


def delete_user(user_id: int):
    db: Session = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="해당 사용자를 찾을 수 없습니다.")

    db.delete(user)
    db.commit()

    return {"msg": "사용자가 삭제되었습니다."}


def update_user(user_id: int, update: UserUpdate):
    db: Session = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="해당 사용자를 찾을 수 없습니다.")

    # 이메일 변경 시 중복 검사
    if update.email and update.email != user.email:
        existing_user = db.query(User).filter(User.email == update.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="이미 사용 중인 이메일입니다.")
        user.email = update.email

    # 비밀번호 해싱 후 저장
    if update.password:
        user.password_hash = hash_password(update.password)

    if update.nickname:
        user.nickname = update.nickname

    db.commit()
    db.refresh(user)

    return {
        "msg": "사용자 정보가 수정되었습니다.",
        "id": user.id,
        "email": user.email,
        "nickname": user.nickname
    }

############################################################################################
def get_user_profile(user_id: int) -> UserProfile:
    # 여기선 user_id를 이메일로 바꿔야 할 수도 있어. 예시용으로 둠
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
    user = fake_users_db.get(user_id)  # 마찬가지로 이메일 기반으로 수정할 수 있음
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if update_data.nickname:
        user["nickname"] = update_data.nickname
    if update_data.language:
        user["language"] = update_data.language

    return UserProfile(**user)
