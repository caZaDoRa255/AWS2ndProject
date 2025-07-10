import boto3
from PIL import Image
import urllib.parse
import json
import requests # 이 라이브러리가 Lambda 배포 패키지에 포함되어야 합니다!
import os

# 람다 환경 변수에서 불러옵니다.
FASTAPI_BACKEND_URL = os.environ.get("FASTAPI_BACKEND_URL")
# 람다 환경 변수에 이 이름(LAMBDA_CALLBACK_SECRET)으로 FastAPI의 SECRET_KEY와 동일한 값을 설정해야 합니다.
LAMBDA_CALLBACK_SECRET = os.environ.get("LAMBDA_CALLBACK_SECRET")

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    # 이벤트에서 버킷 이름과 키(파일 경로) 추출
    bucket = event['Records'][0]['s3']['bucket']['name']
    s3_original_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    
    print(f"Processing file: s3://{bucket}/{s3_original_key}")

    file_extension = os.path.splitext(s3_original_key)[1]
    
    # /tmp 경로에 다운로드 (/tmp 경로는 Lambda에서 유일하게 쓰기 가능한 디렉토리)
    download_path = f'/tmp/original{file_extension}' # 예: /tmp/original.jpg
    upload_path = f'/tmp/thumbnail{file_extension}'   # 예: /tmp/thumbnail.jpg


    thumbnail_unique_id = s3_original_key.split('/')[-1].split('.')[0]
    s3_thumbnail_key = f"thumbnails/{thumbnail_unique_id}{file_extension}"
    
    try:
        print("Downloading file from S3...")
        s3.download_file(bucket, s3_original_key, download_path)
        print("Download complete.")

        # 이미지 처리
        print("Opening image...")
        with Image.open(download_path) as img:
        # 크기 조정 (예: 200x200으로 크롭)
          img.thumbnail((200, 200))
          img.save(upload_path)
        print("Image processing complete.")
    
        # S3에 업로드
        s3.upload_file(upload_path , bucket, s3_thumbnail_key)
        print("Upload complete.")
        # + file_extension : 이게 있으면 이미지.jpg.jpg 이렇게 될수있어서 일단 삭제
        print(f"Thumbnail saved at: s3://{bucket}/{s3_thumbnail_key}")

        # --- S3 객체 메타데이터에서 Content ID 가져오기 ---
        obj_head = s3.head_object(Bucket=bucket, Key=s3_original_key)
        content_id_from_metadata = obj_head['Metadata'].get('content-id')

        if not content_id_from_metadata:
            print("Warning: 'content-id' 메타데이터를 S3 객체에서 찾을 수 없습니다. 콜백을 건너뜝니다.")
            return { 'statusCode': 200, 'body': json.dumps('썸네일 생성은 완료되었으나, Content ID 누락으로 콜백은 건너뛰었습니다.') }

        callback_url = f"{FASTAPI_BACKEND_URL}/internal/assets/thumbnail_callback"

        payload = {
            "content_id": int(content_id_from_metadata), # FastAPI가 int로 받으므로 변환
            "s3_original_key": s3_original_key,
            "s3_thumbnail_key": s3_thumbnail_key,
            "secret": LAMBDA_CALLBACK_SECRET # 보안을 위한 공유 시크릿 키
        }

        print(f"Calling FastAPI callback at {callback_url}...")
        response = requests.post(callback_url, data=payload, timeout=10)
        # , timeout=10 추가함
        print(f"Callback response: {response.status_code} {response.text}")
        response.raise_for_status() # HTTP 오류 발생 시 예외 처리

        print(f"FastAPI로 콜백 성공: {response.status_code} - {response.text}")

        return {
            'statusCode': 200,
            'body': json.dumps('썸네일 생성 및 콜백 성공적으로 전송!')
        }

    except Exception as e:
        print(f"오류 발생 ({s3_original_key} 처리 중): {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'이미지 처리 중 오류 발생: {str(e)}')
        }

    