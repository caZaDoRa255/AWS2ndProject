from fastapi import APIRouter, Depends, HTTPException, Query, Form
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User , LoginRequest, TokenResponse
from app.auth.utils import verify_password, create_access_token  # 암호 비교 & 토큰 생성 함수

from app.models.contents import ContentCreate, ContentResponse, Content
from app.admin.service import create_content, create_subscription_plan
from app.auth.utils import get_current_user

from app.models.subscription import SubscriptionPlanCreate, SubscriptionPlanResponse, SubscriptionPlan

import boto3
import os
import logging

import uuid
from pytube import YouTube

router = APIRouter(prefix="/admin", tags=["Admin"])

# s3 설정값
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
BUCKET_NAME = "ott-project-video-storage-team4-ott-project"
REGION = "ap-northeast-2"

s3_client = boto3.client(
    's3',
    region_name=REGION,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY
)

# ✅ 로그 설정 (클라우드와치)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    filename="/var/log/myapp.log",  # CloudWatch가 수집할 경로
    filemode="a" #filename= 으로 지정한 파일을 어떤 방식으로 열 것인지 지정,append (추가 모드),보통이걸씀
)
logger = logging.getLogger(__name__)

# __name__은 현재 모듈 이름 (예: admin.router)
# 이걸 로거 이름으로 쓰면:
# 로그 메시지의 출처를 식별할 수 있고
# 나중에 파일별로 로그 필터링하거나 레벨 조정하기 쉬움

# %(asctime)s	  로그 발생 시간 (예: 2025-06-27 22:12:45)
# %(levelname)s	  로그 레벨 (INFO, ERROR, WARNING 등)
# %(message)s	  네가 logger로 남기는 진짜 메시지 ("[스트리밍 실패] content_id=5..." 등)

#  다운로드 폴더
DOWNLOAD_DIR = "backend/downloads"  #다운로드 실행 시 한번만 실행

# 폴더 없으면 생성
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

#  다운로드 API
# 관리자페이지에서 작성시 예
# 비디오 아이디 (1)
# 영상 제목 (케이팝 데몬헌터스)
# YouTube URL (https://www.youtube.com/watch?v=3JTVQTk36R8&t=12s)
@router.post("/videos/download")
def download_youtube_video(
    video_id: int = Form(...),
    youtube_url: str = Form(...),
    title: str = Form(...),  #  이 3개를 관리자가 입력
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능합니다.")

    try:
        yt = YouTube(youtube_url)
        stream = yt.streams.filter(file_extension='mp4', progressive=True).order_by('resolution').desc().first()
        if not stream:
            raise HTTPException(status_code=404, detail="MP4 영상 스트림을 찾을 수 없습니다.")

        safe_title = title.strip().replace("/", "-").replace("\\", "-")
        filename = f"{video_id}_{safe_title}.mp4"
        filepath = os.path.join(DOWNLOAD_DIR, filename)

        stream.download(output_path=DOWNLOAD_DIR, filename=filename)

        logging.info(f"[다운로드 완료] video_id={video_id}, url={youtube_url}, file={filename}")
        return {
            "message": "다운로드 성공",
            "file": filename,
            "video_id": video_id
        }

    except Exception as e:
        logging.error(f"[다운로드 실패] video_id={video_id}, error={str(e)}")
        raise HTTPException(status_code=500, detail="영상 다운로드 중 오류 발생")


#  리스트 반환 API (관리자 확인용, 다운로드된 영상이 맞는지 확인(품질, 내용),
# s3 올릴때나 컨텐츠 저장할때 순서 헷갈리지않게 확인 가능!)
# 파일 옆에 "업로드" 버튼을 추가하는 식으로→ 영상마다 개별 확인 + 업로드 진행 가능
# -> 버튼을 누르면 S3 presigned URL 요청 → PUT으로 로컬 파일 업로드 → 성공 메시지 출력
@router.get("/videos/pending-uploads")
def list_pending_videos(
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능합니다.")

    files = []
    for filename in os.listdir(DOWNLOAD_DIR):
        if filename.endswith(".mp4"):
            parts = filename.split("_", 1)
            if len(parts) == 2 and parts[0].isdigit():
                vid = int(parts[0])
                title = parts[1]
            else:
                vid = None
                title = filename

            files.append({
                "video_id": vid,
                "filename": filename,
                "path": f"{DOWNLOAD_DIR}/{filename}"
            })

    return {"videos": files}

# 영상 업로드용 url
@router.post("/videos/upload-url")
def generate_upload_url(
    video_id: int,
    current_user: User = Depends(get_current_user)  # 관리자 인증
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능합니다")

    try:
        key = f"video/{video_id}.mp4"  
        #관리자가 어떤 영상이름으로 올리든(예:미니언즈.mp4) s3에는 영상이름이 video/1.mp4 이런식으로 저장됨
        url = s3_client.generate_presigned_url(
            ClientMethod='put_object',
            Params={'Bucket': BUCKET_NAME, 'Key': key, 'ContentType': 'video/mp4'},
            ExpiresIn=3600  #1시간 사용가능 , 이 시간 내에 업로드(PUT 요청)해야함
        )
        logger.info(f"[관리자 presigned URL 발급] video_id={video_id}, key={key}, admin_id={current_user.id}")
        return {"upload_url": url, "key": key}
    
    # URL 발급 실패 시 백엔드 에러를 안전하게 리턴(예:AWS 키가 잘못됨,S3 권한 없음,네트워크 오류,버킷 이름)
    except Exception as e: 
        logger.error(f"[presigned URL 발급 실패] video_id={video_id}, admin_id={current_user.id}, error={str(e)}")
        raise HTTPException(status_code=500, detail="영상 URL 발급에 실패했습니다.")
    
# 관리자 로그인
@router.post("/login", response_model=TokenResponse)
def admin_login(
    login_req: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == login_req.email).first()
    if not user or not verify_password(login_req.password, user.password_hash) or not user.is_admin:
        raise HTTPException(status_code=401, detail="운영자 권한 없거나 정보 불일치")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token)
# 운영자는 보안상 Access만 사용 (수동 로그인), 유저만 자동연장 사용

# 콘텐츠 등록
@router.post("/content", response_model=ContentResponse)
def admin_add_content(
    content_data: ContentCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능")
    return create_content(db, content_data)

# 이용권 등록
@router.post("/subscription", response_model=SubscriptionPlanResponse)
def add_subscription_plan(
    plan_data: SubscriptionPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능")
    return create_subscription_plan(db, plan_data)

# # 🔹 콘텐츠 테스트 등록용
# @router.post("/test/content")
# def test_add_content_query(
#     title: str = Query(...),
#     description: str = Query(""),
#     category: str = Query(...),
#     year: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     content = Content(
#         title=title.strip(),
#         description=description.strip(),
#         category=category.strip(),
#         year=year
#     )
#     db.add(content)
#     db.commit()
#     db.refresh(content)
#     return content

# # 🔹 이용권 테스트 등록용
# @router.post("/test/subscription")
# def test_add_subscription_query(
#     name: str = Query(...),
#     description: str = Query(""),
#     price: int = Query(...),
#     duration_days: int = Query(...),
#     db: Session = Depends(get_db)
# ):
#     plan = SubscriptionPlan(
#         name=name.strip(),
#         description=description.strip(),
#         price=price,
#         duration_days=duration_days
#     )
#     db.add(plan)
#     db.commit()
#     db.refresh(plan)
#     return plan