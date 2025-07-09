from fastapi import APIRouter, Depends, HTTPException, Query, Form
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User , LoginRequest, TokenResponse
from app.auth.utils import verify_password, create_access_token  # 암호 비교 & 토큰 생성 함수

from app.models.contents import ContentCreate, ContentResponse, Content, ContentUpdateThumbnailCallback
from app.admin.service import create_content, create_subscription_plan
from app.auth.utils import get_current_user
from app.contents.crud import create_content_record, get_content_by_id, update_content_thumbnail 
from app.models.subscription import SubscriptionPlanCreate, SubscriptionPlanResponse, SubscriptionPlan

import boto3
import os
import logging

import uuid
from pytube import YouTube
from mimetypes import guess_type

router = APIRouter(prefix="/admin", tags=["Admin"])

# s3 설정값
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
BUCKET_NAME_IMAGES = "image-storage-team4-ott-project"
BUCKET_NAME_VIDEOS = "ott-project-video-storage-team4-ott-project"
REGION = "ap-northeast-2"

s3_client = boto3.client(
    's3',
    region_name=REGION,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY
)

# 람다 시크릿은 기존 .env의 SECRET_KEY 환경 변수에서 로드
LAMBDA_CALLBACK_SECRET = os.getenv("SECRET_KEY")

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

# 이미지 업로드용 Presigned URL 발급
@router.post("/images/upload-url", response_model=ContentResponse)
def generate_image_upload_url(
    content_data: ContentCreate = Depends(), # 제목, 설명, 카테고리, 연도를 받음
    filename: str = Form(..., description="업로드할 원본 이미지 파일 이름 (예: my_image.jpg)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user) # 관리자 인증
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="운영자만 접근 가능합니다")

    try:
        # 파일 확장자 추출
        file_extension = os.path.splitext(filename)[1] # 예: ".jpg", ".png"
        # UUID를 사용하여 유니크한 파일 이름 생성
        # 이렇게 하면 같은 이름의 파일을 여러 번 업로드해도 덮어쓰지 않고 새로운 파일로 저장
        unique_s3_id = str(uuid.uuid4())
        

        # S3에 저장될 Key 정의
        # 람다 트리거의 filter_prefix인 "uploads/"와 일치해야함
        s3_original_key = f"uploads/{unique_s3_id}{file_extension}"

        # 파일 확장자를 기반으로 Content-Type 유추
        # S3에 올바른 Content-Type으로 저장되어야 웹 브라우저에서 올바르게 표시됩니다.
        guessed_content_type = guess_type(filename)[0] # 예: 'image/jpeg', 'image/png'
        # 유추 실패 시 기본값 (안전한 바이너리 스트림)
        final_content_type = guessed_content_type if guessed_content_type else 'application/octet-stream'

        # DB에 콘텐츠 레코드 미리 생성 (S3 업로드 전)
        new_content_record = create_content_record(
            db=db,
            content_data=content_data,
            #s3_original_key=s3_original_key ->여기주석처리하기
        )
        content_id_from_db = new_content_record.id

        # S3 Presigned URL 발급
        url = s3_client.generate_presigned_url(
            ClientMethod='put_object',
            Params={
                'Bucket': BUCKET_NAME_IMAGES,
                'Key': s3_original_key,
                'ContentType': final_content_type, # 유추된 Content-Type 사용
                'Metadata': {
                    'content-id': str(content_id_from_db) # DB ID를 S3 메타데이터로 저장
                }
            },
            ExpiresIn=3600 # 1시간 유효
        )

        logger.info(f"[관리자 presigned 이미지 URL 발급] key={s3_original_key}, admin_id={current_user.id}, content_type={final_content_type},content_id={content_id_from_db}")
        # Pydantic ContentResponse 스키마에 맞춰 응답 데이터 준비
        response_data = new_content_record.__dict__.copy() # .copy()를 사용하여 원본 객체 영향 방지
        response_data["upload_url"] = url # 클라이언트에게 업로드 URL 제공
        response_data["s3_original_key"] = s3_original_key # 클라이언트에게 S3 원본 키 제공

        if '_sa_instance_state' in response_data:
            del response_data['_sa_instance_state'] # SQLAlchemy 내부 상태 정보 제거

        return ContentResponse(**response_data) # Pydantic ContentResponse로 반환

    except Exception as e:
        logger.error(f"[이미지 presigned URL 발급 실패] admin_id={current_user.id}, error={str(e)}")
        raise HTTPException(status_code=500, detail="이미지 URL 발급에 실패했습니다.")
    
# 람다 썸네일 콜백을 받을 새로운 API 엔드포인트
@router.post("/internal/assets/thumbnail_callback", status_code=200)
def receive_thumbnail_callback(
    callback_data: ContentUpdateThumbnailCallback = Depends(), # Pydantic 스키마를 통해 데이터 수신
    db: Session = Depends(get_db)
):
    # 콜백 인증 로직
    if not LAMBDA_CALLBACK_SECRET or callback_data.secret != LAMBDA_CALLBACK_SECRET:
        logger.error(f"[썸네일 콜백] Content ID: {callback_data.content_id}에 대한 권한 없는 접근 시도")
        raise HTTPException(status_code=401, detail="Unauthorized callback.")

    try:
        # app/crud/content.py의 get_content_by_id 함수 사용
        content_record = get_content_by_id(db=db, content_id=callback_data.content_id)
        if not content_record:
            logger.warning(f"[썸네일 콜백] DB에서 Content ID를 찾을 수 없음: {callback_data.content_id}")
            raise HTTPException(status_code=404, detail="Content not found.")

        full_thumbnail_url = f"s3://{BUCKET_NAME_IMAGES}/{callback_data.s3_thumbnail_key}"
        updated_content = update_content_thumbnail(
            db=db,
            content_id=callback_data.content_id,
            thumbnail_url=full_thumbnail_url
        )
        if not updated_content:
            logger.error(f"[썸네일 콜백] Content ID: {callback_data.content_id}의 thumbnail_url 업데이트 실패")
            raise HTTPException(status_code=500, detail="Failed to update thumbnail URL.")

        logger.info(f"[썸네일 콜백 수신 및 처리 완료] Content ID: {callback_data.content_id}, 원본 키: {callback_data.s3_original_key}, 썸네일 키: {callback_data.s3_thumbnail_key}")
        return {"message": "Thumbnail callback received and processed successfully."}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[썸네일 콜백 처리 실패] Content ID: {callback_data.content_id}, 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to process thumbnail callback.")    

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
            Params={'Bucket': BUCKET_NAME_VIDEOS, 'Key': key, 'ContentType': 'video/mp4'},
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