from fastapi import FastAPI
from app.auth.router import router as auth_router
from app.contents.router import router as contents_router
from app.favorites.router import router as favorites_router
from app.stream.router import router as history_router
from app.preferences.router import router as preferences_router
from app.recommend.router import router as recommend_router
from app.subscription.router import router as subscription_router
from app.click.router import router as click_router
from app.admin.router import router as admin_router
from app.chatbot.router import router as chatbot_router

app = FastAPI()
app.include_router(auth_router)
app.include_router(contents_router)
app.include_router(favorites_router)
app.include_router(history_router)
app.include_router(preferences_router)
app.include_router(recommend_router)
app.include_router(subscription_router)
app.include_router(click_router)
app.include_router(admin_router)
app.include_router(chatbot_router)

# cd backend_vs
# venv\Scripts\activate
# set PYTHONPATH=backend  : `PYTHONPATH`로 backend 폴더를 루트로 설정
# -> 개발용으로 확인할때는 무조건 작성해줘야함!!, 안하면 main.py위치 잘 읽히지않음
# uvicorn backend.app.main:app --reload   :  로컬에서만 테스트할 때
# 운영/원격 테스트용
# uvicorn backend.app.main:app --host 0.0.0.0 --port 80
#  --host 0.0.0.0 → 모든 네트워크 인터페이스에서 접속 허용
#  --port 80 → Lambda가 요청하는 포트에 맞춤
# http://127.0.0.1:8000/docs ->  Swagger UI확인

# alembic -c backend/alembic.ini revision --autogenerate -m "add ChatLog table(필요한메시지작성)"  :마이그레이션 파일 생성
# alembic -c backend/alembic.ini upgrade head  :마이그레이션 적용 (DB에 테이블 생성)

