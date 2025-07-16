import boto3
from PIL import Image
import urllib.parse
import json
import requests
import os

FASTAPI_BACKEND_URL = os.environ.get("FASTAPI_BACKEND_URL")
LAMBDA_CALLBACK_SECRET = os.environ.get("LAMBDA_CALLBACK_SECRET")
CLOUDFRONT_DOMAIN = os.environ.get("CLOUDFRONT_DOMAIN")

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    bucket = event['Records'][0]['s3']['bucket']['name']
    s3_original_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    
    print(f"Processing file: s3://{bucket}/{s3_original_key}")

    file_extension = os.path.splitext(s3_original_key)[1]
    download_path = f'/tmp/original{file_extension}'
    upload_path = f'/tmp/thumbnail{file_extension}'

    thumbnail_unique_id = s3_original_key.split('/')[-1].split('.')[0]
    s3_thumbnail_key = f"thumbnails/{thumbnail_unique_id}{file_extension}"
    cloudfront_thumbnail_url = f"{CLOUDFRONT_DOMAIN}/{s3_thumbnail_key}"

    try:
        print("Downloading file from S3...")
        s3.download_file(bucket, s3_original_key, download_path)
        print("Download complete.")

        # 이미지 처리
        print("Opening image...")
        with Image.open(download_path) as img:
            img.thumbnail((350, 350))
            img.save(upload_path)
            image_format = img.format.lower()  # 'jpeg', 'png', etc.

        # MIME 타입 매핑
        mime_map = {
            'png': 'image/png',
            'jpeg': 'image/jpeg',
            'jpg': 'image/jpeg',
            'webp': 'image/webp'
        }
        content_type = mime_map.get(image_format, 'application/octet-stream')

        # S3에 Content-Type과 함께 업로드
        with open(upload_path, 'rb') as f:
            s3.upload_fileobj(
                f,
                bucket,
                s3_thumbnail_key,
                ExtraArgs={'ContentType': content_type}
            )
        print(f"Thumbnail uploaded with Content-Type: {content_type}")
        print(f"Thumbnail saved at: s3://{bucket}/{s3_thumbnail_key}")

        # 원본 객체의 메타데이터에서 content-id 추출
        obj_head = s3.head_object(Bucket=bucket, Key=s3_original_key)
        content_id_from_metadata = obj_head['Metadata'].get('content-id')

        if not content_id_from_metadata:
            print("Warning: 'content-id' 메타데이터를 S3 객체에서 찾을 수 없습니다. 콜백을 건너뜝니다.")
            return { 'statusCode': 200, 'body': json.dumps('썸네일 생성은 완료되었으나, Content ID 누락으로 콜백은 건너뛰었습니다.') }

        callback_url = f"{FASTAPI_BACKEND_URL}/internal/assets/thumbnail_callback"

        payload = {
            "content_id": int(content_id_from_metadata),
            "thumbnail_url": cloudfront_thumbnail_url,
            "secret": LAMBDA_CALLBACK_SECRET
        }

        print(f"Calling FastAPI callback at {callback_url}...")
        response = requests.post(callback_url, data=payload, timeout=10)
        print(f"Callback response: {response.status_code} {response.text}")
        response.raise_for_status()

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