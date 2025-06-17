from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from app.models.subscription import SubscriptionPlan, UserSubscription
from sqlalchemy.orm import joinedload #테스트용

# ✅ 유저 구독 저장
def subscribe_user(db: Session, user_id: int, plan_id: int) -> UserSubscription:
    plan = db.query(SubscriptionPlan).filter(SubscriptionPlan.id == plan_id).first()
    if not plan:
        raise ValueError("해당 구독권이 존재하지 않습니다")
    
    # ✅ 이미 구독 중인지 확인 (유효기간 내에 있는 구독이 있으면 예외)
    active_sub = db.query(UserSubscription).filter(
        UserSubscription.user_id == user_id,
        UserSubscription.expires_at > datetime.now(timezone.utc)
    ).first()

    if active_sub:
        raise ValueError("이미 활성화된 구독권이 있습니다.")

    start_date = datetime.now(timezone.utc)
    expires_at = start_date + timedelta(days=plan.duration_days)

    subscription = UserSubscription(
        user_id=user_id,
        subscription_plan_id=plan.id,
        start_date=start_date,
        expires_at=expires_at
    )

    db.add(subscription)
    db.commit()  #쓰기 작업이 성공적으로 반영되도록 마무리하는 명령
    db.refresh(subscription)  #해당 객체를 DB에서 다시 가져와 최신 상태로 갱신
    return subscription

# ✅ 유저 구독 조회
# def get_user_subscription(db: Session, user_id: int):
#     sub = db.query(UserSubscription).join(SubscriptionPlan).filter(UserSubscription.user_id == user_id).order_by(UserSubscription.start_date.desc()).first()
#     if not sub:
#         return None

#     return {
#         "name": sub.subscription_plan.name,
#         "expires_at": sub.expires_at.date()
#     }
# 조회는 읽기-only 작업이기 때문에 commit이나 refresh가 필요 없어

#테스트용(유저 구독 조회)
def get_user_subscription(db: Session, user_id: int):
    sub = (
        db.query(UserSubscription)
        .options(joinedload(UserSubscription.subscription_plan))  # ✅ 이거 추가
        .filter(UserSubscription.user_id == user_id)
        .order_by(UserSubscription.start_date.desc())
        .first()
    )

    if not sub:
        return None

    return {
        "name": sub.subscription_plan.name,
        "expires_at": sub.expires_at.date()
    }
