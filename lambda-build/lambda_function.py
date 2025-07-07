import boto3
from PIL import Image

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # 이벤트에서 버킷 이름과 키(파일 경로) 추출
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    print(f"Processing file: s3://{bucket}/{key}")
    
    # /tmp 경로에 다운로드
    download_path = '/tmp/original.jpg'
    upload_path = '/tmp/thumbnail.jpg'
    output_key = key.replace('uploads/', 'thumbnails/')
    # /tmp 경로는 Lambda에서 유일하게 쓰기 가능한 디렉토리
    
    s3.download_file(bucket, key, download_path)

    # 이미지 처리
    with Image.open(download_path) as img:
        # 크기 조정 (예: 200x200으로 크롭)
        img.thumbnail((200, 200))
        img.save(upload_path)
    
    # S3에 업로드
    s3.upload_file(upload_path, bucket, output_key)
    print(f"Thumbnail saved at: s3://{bucket}/{output_key}")

    #  수정된 코드 없음, s3 엔터티 태그(Etag) 바뀌는지 확인위해 작성
    # 람다가 최신일자로 잘 변경될것인가..