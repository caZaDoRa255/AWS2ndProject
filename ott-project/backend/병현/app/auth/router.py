from fastapi import APIRouter, HTTPException, Response
from app.schemas.user import UserCreate, UserLogin
from app.auth.utils import (
    hash_password, verify_password,
    create_access_token, create_refresh_token
)
from datetime import timedelta
from fastapi.responses import JSONResponse
from app.auth import service as auth_service
from app.schemas.user_profile import UserUpdate,UserProfile

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/signup")
def signup(user: UserCreate):
    return auth_service.signup(user)

@router.post("/login")
def login(user: UserLogin):
    return auth_service.login(user)


@router.get("/me")
def get_user(user_id: int):
    return auth_service.get_user(user_id)

@router.delete("/me")
def get_user(user_id: int):
    return auth_service.delete_user(user_id)

# @router.patch("/me")
# def get_user(user_id: int):
#     return auth_service.update_user(user_id)


# @router.get("/me", response_model=UserProfile)
# def get_my_profile(user_id: int):
#     return auth_service.get_user_profile(user_id)

# @router.patch("/me", response_model_exclude_none=True)
# def update_my_profile(user_id: int, update: UserUpdate):
#     return auth_service.update_user_profile(user_id, update)

# @router.delete("/me")