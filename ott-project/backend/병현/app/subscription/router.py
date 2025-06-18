# from fastapi import APIRouter, Depends, HTTPException
# from sqlalchemy.orm import Session
# from app.db.session import get_db  
# from app.subscription.service import subscribe_user, get_user_subscription
# from app.models.subscription import Subscription  # API 응답용 Pydantic
# from typing import Optional

# router = APIRouter(
#     prefix="/subscribe",
#     tags=["Subscription"]
# )

# # ✅ 1. 구독하기
# @router.post("/{plan_id}", response_model=Subscription)
# def subscribe(plan_id: int, db: Session = Depends(get_db), user_id: int = 1):
#     try:
#         subscription = subscribe_user(db, user_id, plan_id)
#         return Subscription(name=subscription.subscription_plan.name, expires_at=subscription.expires_at)
#     except ValueError as e:
#         raise HTTPException(status_code=404, detail=str(e))

# # ✅ 2. 내 구독 조회
# @router.get("/me", response_model=Optional[Subscription], response_model_exclude_none=True)
# def get_my_subscription(db: Session = Depends(get_db), user_id: int = 1):
#     result = get_user_subscription(db, user_id)
#     if result:
#         return Subscription(**result)
#     return None

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db  
from app.subscription.service import subscribe_user, get_user_subscription
from app.models.subscription import Subscription, SubscriptionPlan, SubscriptionPlanOut
from typing import Optional, List


router = APIRouter(
    prefix="/subscribe",
    tags=["Subscription"]
)

# ✅ 1. 구독권 초기 등록 (운영용 아님) -> 1,2번은 테스트용, 하고 지우기
@router.post("/seed")
def seed_subscription_plans(db: Session = Depends(get_db)):
    if db.query(SubscriptionPlan).count() > 0:
        return {"message": "이미 구독권이 존재합니다."}
    
    plans = [
        SubscriptionPlan(name="베이직", price=10000, duration_days=30),
        SubscriptionPlan(name="프리미엄", price=20000, duration_days=30)
    ]
    db.add_all(plans)
    db.commit()
    return {"message": "구독권 등록 완료"}

# ✅ 2. 구독권 목록 조회 (프론트에서 보여줄 때 사용)
@router.get("/plans", response_model=List[SubscriptionPlanOut])
def list_plans(db: Session = Depends(get_db)):
    return db.query(SubscriptionPlan).all()

# ✅ 3. 구독 신청
@router.post("/{plan_id}", response_model=Subscription)
def subscribe(plan_id: int, db: Session = Depends(get_db), user_id: int = 1):
    try:
        _ = subscribe_user(db, user_id, plan_id)

        result = get_user_subscription(db, user_id)

        # ✅ None 체크 먼저
        if not result or not result.get("subscription_plan"):
            return Subscription(name="없음", expires_at=None)

        return Subscription(
            name=result["subscription_plan"]["name"],
            expires_at=result.get("expires_at")
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


# ✅ 4. 내 구독 정보 조회
@router.get("/me", response_model=Optional[Subscription], response_model_exclude_none=True)
def get_my_subscription(db: Session = Depends(get_db), user_id: int = 1):
    result = get_user_subscription(db, user_id)

    # ✅ None 체크 먼저
    if not result or not result.get("subscription_plan"):
        return Subscription(name="없음", expires_at=None)

    return Subscription(
        name=result["subscription_plan"]["name"],
        expires_at=result.get("expires_at")
    )

