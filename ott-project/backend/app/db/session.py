from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv

# # ✔️ 너가 사용할 DB URL로 수정할 것!
# SQLALCHEMY_DATABASE_URL = "sqlite:///backend/app.db"
# # # 예시: "mysql+pymysql://user:password@localhost/dbname"
# # # 예시: "postgresql://user:password@localhost/dbname"

# # # SQLite일 경우는 이 옵션 필요
# engine = create_engine(
#     SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
# )
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# db로 연결설정
load_dotenv()  # .env 파일을 로드한다
DATABASE_URL = os.getenv("DATABASE_URL")  # .env 안에 있는 DATABASE_URL 값을 불러온다

# SQLAlchemy 엔진 생성
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# 세션 팩토리 설정
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# create_engine(...) ->	SQLAlchemy가 RDS(MySQL)랑 연결할 때 사용하는 엔진 생성기
# pool_pre_ping=True ->	오래된 연결로 인한 오류를 방지 (안정성 높임)
# sessionmaker(...)	 -> DB 세션을 만들기 위한 팩토리 함수야. 요청마다 db = SessionLocal() 이런 식으로 씀

# ✅ FastAPI에서 의존성 주입용으로 사용하는 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
