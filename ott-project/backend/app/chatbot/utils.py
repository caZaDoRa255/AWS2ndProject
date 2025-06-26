import re
from sqlalchemy.orm import Session
from app.models.contents import Content

#  이 정규식은 < > 사이에 있는 내용을 전부 리스트로 추출
def extract_titles_from_text(text: str) -> list[str]:
    """
    <제목> 형식의 콘텐츠 제목을 추출하는 함수
    예: "<어바웃 타임>, <미나리>" → ["어바웃 타임", "미나리"]
    """
    return re.findall(r"<(.*?)>", text)

# 제목 정규화 함수
def normalize_title(title: str) -> str:
    """
    공백 제거, 괄호 제거, 특수문자 제거 등으로 제목 정규화
    """
    title = title.lower()
    title = re.sub(r'\s+', '', title)            # 공백 제거
    title = re.sub(r'\(.*?\)', '', title)        # 괄호  제거
    title = re.sub(r'[^가-힣a-z0-9]', '', title)  # 특수문자 제거
    return title


def filter_existing_titles(titles: list[str], db: Session) -> list[str]:
    """
    Gemini 추천 제목들 중 DB에 존재하는 것만 필터링해서 반환
    """
    db_contents = db.query(Content).all()

    # DB의 콘텐츠 제목을 정규화해서 매핑 딕셔너리 생성
    normalized_db_titles = {
        normalize_title(content.title): content.title for content in db_contents
    }

    result = []
    for title in titles:
        norm = normalize_title(title)
        if norm in normalized_db_titles:
            result.append(normalized_db_titles[norm])  # 원래 제목 반환

    return result

# 추천 질문 여부 판단 함수
def is_recommendation_question(text: str) -> bool:
    keywords = ["추천", "볼만한", "챙겨봐야", "비슷한", "보기좋은", "작품","영화","드라마","예능","명작","볼까","좋을까"]
    return any(keyword in text for keyword in keywords)
