from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import timedelta

from app.models.user import UserCreate, UserLogin, User  
from app.auth.utils import (
    hash_password, verify_password,
    create_access_token, create_refresh_token
)
from app.db.session import get_db
from app.auth import service as auth_service
from app.models.user_profile import UserUpdate, UserProfile

router = APIRouter(prefix="/auth", tags=["Auth"])

# ✅ 회원가입
@router.post("/signup")
def signup(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")

    hashed_pw = hash_password(user.password)
    new_user = User(
        email=user.email,
        password_hash=hashed_pw,
        nickname=user.nickname
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # ✅ UserProfile도 생성
    auth_service.create_user_with_profile(new_user, db)
    
    return {"msg": "회원가입 완료"}

# ✅ 로그인
@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()

    if not db_user:
        raise HTTPException(status_code=401, detail="존재하지 않는 이메일입니다.")
    if not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="비밀번호가 일치하지 않습니다.")

    access_token = create_access_token(data={"sub": str(db_user.id)})
    refresh_token = create_refresh_token(data={"sub": str(db_user.id)})

    response = JSONResponse(content={"access_token": access_token, "token_type": "bearer"})

    # Refresh Token을 HttpOnly 쿠키에 저장
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        max_age=30 * 24 * 60 * 60,  # 30일
        expires=30 * 24 * 60 * 60,
        path="/",
        samesite="lax",  # 또는 "strict", 필요 시 "none"
        secure=False     # ⚠️ HTTPS일 경우 True로 변경
    )

    return response

# 유저 프로필 조회 
@router.get("/me", response_model=UserProfile, response_model_exclude_none=True)
def get_my_profile(user_id: int, db: Session = Depends(get_db)):
    return auth_service.get_user_profile(user_id, db)

# 유저 프로필 설정 변경
@router.patch("/me", response_model=UserProfile, response_model_exclude_none=True) #만료일이 none일때 나오지않게
def update_my_profile(user_id: int, update: UserUpdate, db: Session = Depends(get_db)):
    return auth_service.update_user_profile(user_id, update, db)

#개발환경 (localhost)
# samesite="lax"
# secure=False

#운영환경 (도메인 + https)
# samesite="None"
# secure=True  # 꼭 True! 아니면 브라우저가 cross-site 쿠키 차단함

