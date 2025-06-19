# 관리자 로그인
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User , LoginRequest, TokenResponse
from app.auth.utils import verify_password, create_access_token  # 암호 비교 & 토큰 생성 함수

from app.models.contents import ContentCreate, ContentResponse, Content
from app.admin.service import create_content, create_subscription_plan
from app.auth.utils import get_current_user

from app.models.subscription import SubscriptionPlanCreate, SubscriptionPlanResponse, SubscriptionPlan

router = APIRouter(prefix="/admin", tags=["Admin"])

# 관리자 로그인
@router.post("/login", response_model=TokenResponse)
def admin_login(
    login_req: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == login_req.email).first()
    if not user or not verify_password(login_req.password, user.password_hash) or not user.is_admin:
        raise HTTPException(status_code=401, detail="운영자 권한 없거나 정보 불일치")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token)
# 운영자는 보안상 Access만 사용 (수동 로그인), 유저만 자동연장 사용

# 콘텐츠 등록
@router.post("/content", response_model=ContentResponse)
def admin_add_content(
    content_data: ContentCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능")
    return create_content(db, content_data)

# 이용권 등록
@router.post("/subscription", response_model=SubscriptionPlanResponse)
def add_subscription_plan(
    plan_data: SubscriptionPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능")
    return create_subscription_plan(db, plan_data)

# # 🔹 콘텐츠 테스트 등록용
# @router.post("/test/content")
# def test_add_content_query(
#     title: str = Query(...),
#     description: str = Query(""),
#     category: str = Query(...),
#     year: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     content = Content(
#         title=title.strip(),
#         description=description.strip(),
#         category=category.strip(),
#         year=year
#     )
#     db.add(content)
#     db.commit()
#     db.refresh(content)
#     return content

# # 🔹 이용권 테스트 등록용
# @router.post("/test/subscription")
# def test_add_subscription_query(
#     name: str = Query(...),
#     description: str = Query(""),
#     price: int = Query(...),
#     duration_days: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     plan = SubscriptionPlan(
#         name=name.strip(),
#         description=description.strip(),
#         price=price,
#         duration_days=duration_days
#     )
#     db.add(plan)
#     db.commit()
#     db.refresh(plan)
#     return plan