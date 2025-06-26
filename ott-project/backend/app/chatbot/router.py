from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.chatbot.service import call_gemini_api, sanitize_and_store
from app.models.chatbot import ChatLog, ChatRequest, ChatResponse
from app.db.session import get_db
from app.subscription.service import has_valid_subscription
from app.models.user import User
from app.auth.utils import get_current_user
from app.chatbot.utils import extract_titles_from_text, filter_existing_titles


router = APIRouter(prefix="/chatbot", tags=["Chatbot"])

@router.post("/", response_model=dict)
def chat_endpoint(
    request: ChatRequest, 
    db: Session = Depends(get_db), 
    user: User = Depends(get_current_user)
):

    # ✅ 유효한 구독권 검사
    if not has_valid_subscription(user.id, db):
        raise HTTPException(status_code=403, detail="이용권이 있어야 챗봇을 사용할 수 있습니다.")
    
    try:
        reply = call_gemini_api(request.message)
    except Exception as e:
        # 예외 시에도 로그 저장(언제부터 API 호출이 실패했는지, 어떤 입력에서 문제였는지 알 수 있음)
        log = ChatLog(
            user_input=request.message,
            gemini_response="[ERROR: Gemini 호출 실패]",
        )
        db.add(log)
        db.commit()
        # 예외 상황에 따른 사용자 메시지 전달
        return {"reply": "⚠️ 답변을 가져오는데 문제가 발생했어요. 잠시 후 다시 시도해주세요."}
    
    # ✅ Gemini 응답에서 추천 제목 추출
    titles = extract_titles_from_text(reply)

    if titles:

        # ✅ 실제 DB에 있는 콘텐츠만 필터링
        valid_titles = filter_existing_titles(titles, db)
        full_list = "\n".join(f"- {title}" for title in titles)

        if valid_titles:
            matched_list = "\n".join(f"- {title}" for title in valid_titles)
            final_reply = (
                f"Gemini가 추천한 작품들:\n{full_list}\n\n"
                f"그중 서비스에 등록된 콘텐츠는 다음과 같아요:\n{matched_list}"
            )
        else:
            final_reply = (
                f"Gemini가 추천한 작품들:\n{full_list}\n\n"
                "하지만 현재 서비스에 등록된 콘텐츠는 없어요."
            )
    else:
        # ✅ 일반 대화는 원문 출력
        final_reply = reply

    # 사용자에게 보여준 최종 답변을 저장!
    _ = sanitize_and_store(request.message, final_reply, db)

    return {"reply": final_reply}


# 이렇게 하면:
# 영화 추천이면 → 정제된 추천 메시지 출력
# 일반 대화면 → Gemini 원문 그대로 출력
# 조건 분기: 추천이면 필터링, 아니면 원본 사용


# ★★★
# # 챗봇이 답할때 줄바꿈 문자(\n)랑 *도 같이 넣어서 답해서 (예:문장1\n\n문장2\n **항목1**) 이런식으로..
# 프론트에서 줄바꿈 처리해줘야한다고해서 부탁해요~!

# 🔹HTML에서 줄바꿈 처리하는 법
# Python API에서는 \n만 넣으면 되고
# 프론트에서 JS/HTML 쪽에서 변환해줘야 돼:
# javascript
# // 예: Vue, React, JS에서 표시할 때
# const formattedReply = reply.replace(/\n/g, "<br>");
# 또는 Markdown 스타일이 있다면 \n*는 <ul><li>처럼 바꿔서 출력해도 좋고
# 라이브러리 (ex. marked.js, react-markdown) 써도 돼.

# 프론트에서만 보기 좋게 렌더링하면 됨:
# \n → <br>
# * 항목 → 리스트 처리



