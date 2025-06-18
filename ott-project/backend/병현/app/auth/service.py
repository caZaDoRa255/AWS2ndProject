from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from datetime import date

from app.models.user import User
from app.models.user_profile import UserUpdate, UserProfile, UserProfileORM
from app.models.subscription import SubscriptionPlan, Subscription

from fastapi import Request
from app.core.config import ALGORITHM, SECRET_KEY
from jose import jwt, JWTError

# ✅ 유저 프로필 조회
def get_user_profile(user_id: int, db: Session) -> UserProfile:
    user = db.query(User).filter(User.id == user_id).first()
    profile = db.query(UserProfileORM).filter(UserProfileORM.id == user_id).first()

    if not user or not profile:
        raise HTTPException(status_code=404, detail="User not found")

    # ✅ 구독권 정보 불러오기
    subscription = None
    if profile.subscription_id:
        sub = db.query(SubscriptionPlan).filter(SubscriptionPlan.id == profile.subscription_id).first()
        if sub:
            subscription = Subscription(
                name=sub.name,
                expires_at=date(2025, 6, 30)  # ⛔️ 임시값 (UserSubscription 연동 예정)
            )
    else:  # 구독권이 없을 경우 "없음" 표시, 만료일 none이면 출력x
        subscription = Subscription(name="없음", expires_at=None)

    # ✅ 사용자에게 돌려줄 최종 응답
    return UserProfile(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language=profile.language,
        subscription=subscription
    )


# ✅ 유저 프로필 수정
def update_user_profile(user_id: int, update: UserUpdate, db: Session) -> UserProfile:
    user = db.query(User).filter(User.id == user_id).first()
    profile = db.query(UserProfileORM).filter(UserProfileORM.id == user_id).first()

    if not user or not profile:
        raise HTTPException(status_code=404, detail="User not found")

    # 🔒 닉네임 필수 항목 검사
    if update.nickname in (None, ""):
        raise HTTPException(status_code=400, detail="닉네임은 필수 항목입니다.")

    # 🔁 닉네임 중복 확인
    if update.nickname not in (None, ""):
        existing = db.query(User).filter(User.nickname == update.nickname, User.id != user_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="이미 사용 중인 닉네임입니다.")
        user.nickname = update.nickname

    # 🌐 언어 수정 (빈 값이면 무시)
    if update.language not in (None, ""):
        profile.language = update.language

    try:
        db.commit()
        db.refresh(user)
        db.refresh(profile)
    except SQLAlchemyError as e:
        db.rollback()
        print("프로필 업데이트 중 오류:", str(e))
        raise HTTPException(status_code=500, detail="프로필 업데이트 실패")

    # ✅ 구독권 정보 다시 조회
    subscription = None
    if profile.subscription_id:
        sub = db.query(SubscriptionPlan).filter(SubscriptionPlan.id == profile.subscription_id).first()
        if sub:
            subscription = Subscription(
                name=sub.name,
                expires_at=date(2025, 6, 30)
            )
    else:
        subscription = Subscription(name="없음", expires_at=None)

    return UserProfile(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language=profile.language,
        subscription=subscription
    )


def delete_user(user_id: int, db: Session) -> dict:
    user = db.query(User).filter(User.id == user_id).first()
    profile = db.query(UserProfileORM).filter(UserProfileORM.id == user_id).first()

    if not user or not profile:
        raise HTTPException(status_code=404, detail="User not found")

    try:
        db.delete(profile)
        db.delete(user)
        db.commit()
    except SQLAlchemyError as e:
        db.rollback()
        print("삭제 중 오류:", str(e))
        raise HTTPException(status_code=500, detail="사용자 삭제 실패")

    return {"detail": "사용자 계정과 프로필이 삭제되었습니다."}



# ✅ 회원가입 시 UserProfile도 생성
def create_user_with_profile(user: User, db: Session, language: str = "kor"):
    try:
        new_profile = UserProfileORM(
            id=user.id,
            email=user.email,
            language=language
        )
        db.add(new_profile)
        db.commit()
    except SQLAlchemyError as e:
        db.rollback()   #에러 나면 DB 작업 전부 되돌림
        print("회원가입 중 에러 발생:", str(e))
        raise HTTPException(status_code=500, detail="프로필 생성 중 오류가 발생했습니다.")
# 예: 회원가입 시 유저테이블,유저프로필테이블에 같이 저장되는데 오류나서 유저테이블만 저장됨
# 롤백하면 유저,유저프로필테이블 모두 저장되지않음
# 롤백? "트랜잭션 도중 문제가 생겼을 때, 이미 진행된 DB 변경 내용을 되돌리는 작업"

# 토큰을 id로 디코딩하는 로직. 병현 추가.
def get_user_id_from_cookie(request: Request) -> int:
    token = request.cookies.get("access_token")
    ## 임시 코드 토큰 강제 주입함. 쿠키를 브라우저에서 가지고 오는건 프론트에서만 가능하다.
    # token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3IiwiZXhwIjoxNzQ5OTA1MDE0fQ.TnKsT35Ps8lFqcxTIpNqrNwv4Kk5ZUZvAbbxWQnzpV0"
    if not token:
        raise HTTPException(status_code=401, detail="로그인 정보가 없습니다.")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="토큰에 사용자 정보가 없습니다.")
        return int(user_id)
    except JWTError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")