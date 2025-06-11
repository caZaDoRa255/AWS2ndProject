from fastapi import FastAPI
from app.auth.router import router as auth_router
from app.contents.router import router as contents_router
from app.favorites.router import router as favorites_router
from app.stream.router import router as history_router
from app.preferences.router import router as preferences_router
from app.recommend.router import router as recommend_router


#------------------
from app.db.session import engine
from app.db.models.user import User
from app.db.base import Base

app = FastAPI()

# 실행 시 테이블 생성
Base.metadata.create_all(bind=engine)


from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # Vite dev 서버 주소
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth_router)
app.include_router(contents_router)
app.include_router(favorites_router)
app.include_router(history_router)
app.include_router(preferences_router)
app.include_router(recommend_router)

# cd backend_vs
# venv\Scripts\activate
# set PYTHONPATH=backend  : `PYTHONPATH`로 backend 폴더를 루트로 설정
# -> 개발용으로 확인할때는 무조건 작성해줘야함!!, 안하면 main.py위치 잘 읽히지않음
# uvicorn backend.app.main:app --reload
# http://127.0.0.1:8000/docs ->  Swagger UI확인
