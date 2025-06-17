from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import Session

# ✔️ 너가 사용할 DB URL로 수정할 것!
SQLALCHEMY_DATABASE_URL = "sqlite:///backend/app.db"
# 예시: "mysql+pymysql://user:password@localhost/dbname"
# 예시: "postgresql://user:password@localhost/dbname"

# SQLite일 경우는 이 옵션 필요
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ✅ FastAPI에서 의존성 주입용으로 사용하는 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
