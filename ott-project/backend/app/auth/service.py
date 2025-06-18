from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from datetime import date

from app.models.user import User
from app.models.user_profile import UserUpdate, UserProfile, UserProfileORM
from app.models.subscription import SubscriptionPlan, Subscription
from app.models.preference import UserPreference


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

    # ✅ 선호도 조회 추가
    preferences_query = db.query(UserPreference).filter(UserPreference.user_id == user_id).all()
    preferences = [p.genre for p in preferences_query]

    # ✅ 사용자에게 돌려줄 최종 응답
    return UserProfile(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language=profile.language,
        subscription=subscription,
        preferences=preferences
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

    # ✅ 선호도 수정 (덮어쓰기 방식)
    if update.preferences is not None:
        db.query(UserPreference).filter_by(user_id=user_id).delete()
        for genre in update.preferences:
            db.add(UserPreference(user_id=user_id, genre=genre))

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

    # ✅ 선호도 재조회 (업데이트 결과 포함)
    preferences_query = db.query(UserPreference).filter(UserPreference.user_id == user_id).all()
    preferences = [p.genre for p in preferences_query]

    return UserProfile(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language=profile.language,
        subscription=subscription,
        preferences=preferences
    )


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
