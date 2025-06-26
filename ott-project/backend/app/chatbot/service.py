import os
import re
import requests
from typing import Optional
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from app.models.chatbot import ChatLog
from app.chatbot.utils import is_recommendation_question

# ✅ Gemini 호출 함수
def call_gemini_api(user_input: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY") # .env에서 받아옴
    endpoint = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"
    # Gemini API 호출을 위한 공식 엔드포인트 (Gemini 1.5 Flash 모델(빠르고 최신)사용)
    # https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent -> pro모델(기본)

    # ✅ 조건에 따른 프롬프트(라우터의 필터링이랑 같이 조합해서 답변함)
    if is_recommendation_question(user_input):  #추천용
       prompt = f"""
       너는 OTT 플랫폼의 콘텐츠 추천 전문가야.
       우리 서비스에는 영화, 드라마, 예능 등 다양한 장르의 콘텐츠가 등록되어 있어.
       사용자가 아래와 같은 질문을 했을 때, 우리 서비스에 등록되어 있을 법한 콘텐츠를 3~5개 추천해줘.
       각 추천에는 간단한 설명도 함께 포함해줘.

       사용자 질문: "{user_input}"
       """
    else:
        prompt = user_input  # 일반 질문은 그대로 전달(추천 아닌 질문은 그대로 자연스러운 대화 가능)

    headers = {"Content-Type": "application/json"}
    body = {
        "contents": [
            {
                "parts": [{"text": prompt}]
            }
        ]
    }

    response = requests.post(
        f"{endpoint}?key={api_key}",
        headers=headers,
        json=body
    )
    data = response.json()
    return data["candidates"][0]["content"]["parts"][0]["text"] # Gemini의 응답 텍스트 본문

# ✅ 민감정보 마스킹 (전화번호, 이메일, 이름만)
def mask_sensitive_info(text: str) -> str:
    text = re.sub(r'\b(01[0-9])[- ]?(\d{3,4})[- ]?(\d{4})\b', r'\1-****-\3', text)  # 전화번호
    text = re.sub(r'[\w\.-]+@[\w\.-]+', '[EMAIL]', text)  # 이메일
    # text = re.sub(r'\b[가-힣]{2,4}\b', '[NAME]', text)    # 이름 단순 마스킹
    # 이름이 아닌것들고 너무 깨져서 일단 제거
    return text

# ✅ 너무 구체적인 주소 포함 여부 확인
def contains_precise_address(text: str) -> bool:
    patterns = [
        r'\d{3,}-\d{1,}',  # "123-4" 같은 번지
        r'[가-힣]{2,}(시|군|구)\s?[가-힣]{2,}(동|읍|면)',  # 예: 서울시 강남구 역삼동
        # r'(아파트|빌라|오피스텔|주공|리버뷰|힐스테이트|래미안)'  # 아파트 키워드 ,너무 엄격하게 저장되서 제거
        # 완벽한 주소만 마스킹되도록함(서울시 종로구,강남,서울 이런거는 마스킹x -> 로그 분석, 추천 데이터 확보에 손해)
    ]
    return any(re.search(p, text) for p in patterns)

# ✅ 마스킹 + 저장 로직 (구체주소 있으면 저장 안 함)
def sanitize_and_store(user_input: str, gemini_response: str, db: Session) -> Optional[ChatLog]:
    if contains_precise_address(user_input) or contains_precise_address(gemini_response):
        # 민감정보 포함 → 내용 마스킹해서 저장
        log = ChatLog(
            user_input="[FILTERED: 민감 정보로 인해 저장되지 않음]",
            gemini_response="[FILTERED: 민감 정보로 인해 저장되지 않음]"
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return None  # 로그 내용은 None으로 리턴

    # 일반적인 경우: 마스킹 후 저장
    clean_input = mask_sensitive_info(user_input)
    clean_response = mask_sensitive_info(gemini_response)

    log = ChatLog(user_input=clean_input, gemini_response=clean_response)
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

# 나중에 디테일로 할 수 있으면 로그삭제도 해보기
#  FastAPI 쪽에 "로그 삭제 API" 만들기 
# @router.post("/purge-chat-logs")
# def purge_logs(db: Session = Depends(get_db)):
#     delete_old_chat_logs(db)
#     return {"message": "7일 지난 대화 로그 삭제 완료"}
#  GCP Cloud Scheduler에서 이 API를 호출하도록 설정 (“언제, 어떻게 실행할지”를 자동화하는 도구)
# 위 2개도 설정해줘야함

# # ✅ 일정 기간 지난 로그 삭제 함수 (“7일 이상 된 로그를 지워주는 기능”만 정의됨)
# def delete_old_chat_logs(db: Session, days: int = 7):
#     cutoff = datetime.now(timezone.utc) - timedelta(days=days)
#     db.query(ChatLog).filter(ChatLog.created_at < cutoff).delete()
#     db.commit()