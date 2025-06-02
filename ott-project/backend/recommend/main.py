# 📁 backend/main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI()

# 🧾 데이터 모델 (Pydantic)
class User(BaseModel):
    username: str
    email: str
    preference: List[str]  # ex: ["액션", "로맨스"]

class ClickLog(BaseModel):
    username: str
    content_id: str
    timestamp: str

class RecommendRequest(BaseModel):
    keyword: str

# 📦 더미 DB (테스트용)
users_db = {}
click_logs = []

# ✅ 1. 회원가입
@app.post("/signup")
def signup(user: User):
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다")
    users_db[user.username] = user
    return {"message": f"{user.username} 가입 성공!"}

# ✅ 2. 클릭 로그 저장
@app.post("/click")
def click(log: ClickLog):
    click_logs.append(log)
    return {"message": "클릭 로그 저장 완료"}

# ✅ 3. 추천 API (키워드 기반)
@app.post("/recommend")
def recommend(req: RecommendRequest):
    keyword = req.keyword.lower()
    dummy_results = [
        {"title": "액션 다큐", "thumbnail": "https://img.url/1.jpg"},
        {"title": "로맨스 판타지", "thumbnail": "https://img.url/2.jpg"},
    ]
    result = [item for item in dummy_results if keyword in item["title"].lower()]
    return {"results": result}

# ✅ 4. 프리사인 URL 생성 (테스트용)
@app.get("/stream/{content_id}")
def get_presigned_url(content_id: str):
    # 실제 환경에서는 S3 Presigned URL 생성 코드 필요
    return {
        "content_id": content_id,
        "presigned_url": f"https://s3.bucket/{content_id}.mp4?token=abc123"
    }
