from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool, create_engine
from alembic import context
from configparser import BasicInterpolation
from dotenv import load_dotenv
import os, sys

# ✅ 환경변수 불러오기 전에 interpolation(치환(값 삽입) 기능) 설정 먼저
# 반드시 환경변수 설정 (set_main_option) 전에 interpolation 설정
# 순서 바뀌면 → 이미 interpolation 오염된 상태에서 값 넣게 돼서 에러 발생
# context.config.file_config._interpolation = BasicInterpolation() #rds는 비번에 특수기호있어서 필요,gcp에서는 비번에 특수문자 없으므로 필요x
# BasicInterpolation()은 치환 기능을 약하게 줄여줌
# %가 들어가 있어도 더 이상 "치환용"으로 간주하지 않음
# 즉, "이건 치환하지 마, 그냥 문자열로 읽어"라고 설정해줌

# 한 후 config설정
config = context.config
#  context.config는 Alembic 내부에서 alembic.ini 설정 전체를 불러온 객체

# 경로 추가
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# .env 로드
dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
load_dotenv(dotenv_path)
# load_dotenv()

# ✅ DB URL 제대로 불러오는지 확인용
print("✅ DB URL:", os.getenv("DATABASE_URL"))

# Alembic config
# config = context.config
# config.file_config._interpolation = BasicInterpolation()

# ✅ DB URL 주입
# config.set_main_option("sqlalchemy.url", os.getenv("DATABASE_URL"))
# 자꾸 에러발생, 인코딩한 %부분을 문자열로 받아들이지못함, 치환대상으로 생각함(인코딩된 문자에서 interpolation 충돌 발생)
# 밑에서 create_engine(os.getenv("DATABASE_URL") 이렇게 바로 생성시키는걸로 바꿈

# 로깅 설정
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 메타데이터 대상
from app.db.base import Base
from app import models  # 모델 등록용 import
target_metadata = Base.metadata

# 실제 DB에 연결하지 않음, 테스트용
def run_migrations_offline() -> None:
    """오프라인 마이그레이션"""
    context.configure(
        url=os.getenv("DATABASE_URL"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

# 운영용
def run_migrations_online() -> None:
    """온라인 마이그레이션"""
    # connectable = engine_from_config(  # 이게 ini 설정을 해석하면서 % 충돌이 남
    #     {"sqlalchemy.url": os.getenv("DATABASE_URL")},
    #     config.get_section(config.config_ini_section, {}),
    #     prefix="sqlalchemy.",
    #     poolclass=pool.NullPool,
    # )
    
    connectable = create_engine(os.getenv("DATABASE_URL"), poolclass=pool.NullPool)
    # (alembic.ini에서 URL 가져오지 말고, 파이썬 코드 안에서 환경변수로 직접 DB 엔진을 생성)


    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()


# 실행
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
