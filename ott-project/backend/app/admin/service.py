from sqlalchemy.orm import Session
from app.models.contents import Content, ContentCreate
from app.models.subscription import SubscriptionPlan,SubscriptionPlanCreate

# 컨텐츠 등록
def create_content(db: Session, content_data: ContentCreate) -> Content:
    new_content = Content(
        title=content_data.title,
        description=content_data.description,
        category=content_data.category,
        year=content_data.year,
    )
    db.add(new_content)
    db.commit()
    db.refresh(new_content)
    return new_content

# 이용권 등록
def create_subscription_plan(db: Session, plan_data: SubscriptionPlanCreate) -> SubscriptionPlan:
    plan = SubscriptionPlan(
        name=plan_data.name,                   # Pydantic에서 이미 .strip() 처리됨
        description=plan_data.description,     # None이면 Pydantic에서 처리됨
        price=plan_data.price,
        duration_days=plan_data.duration_days
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan