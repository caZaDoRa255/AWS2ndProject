FROM python:3.10-slim

# 작업 디렉토리 지정
WORKDIR /app

# 코드 복사
COPY . .

# 의존성 설치
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# FastAPI 실행 (uvicorn 기준)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
