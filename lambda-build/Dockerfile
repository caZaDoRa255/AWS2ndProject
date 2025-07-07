# FROM amazonlinux:2
# Runtime.ImportModuleError 이런 오류가 나서 람다에서 설정한 파이썬버전이랑 같게 작성함

FROM public.ecr.aws/lambda/python:3.11
# AWS에서 공식적으로 제공하는 AWS ECR(Elastic Container Registry) Public Gallery에 호스팅된 이미지

# Pillow가 요구하는 시스템 라이브러리들을 설치합니다.
# 이 라이브러리들이 없으면 _imaging 등의 C 확장이 제대로 컴파일/로딩되지 않습니다.
RUN yum install -y \
    libSM \
    libXext \
    libXrender \
    fontconfig \
    freetype-devel \
    libjpeg-turbo-devel \
    zlib-devel \
    # 다른 이미지 처리 라이브러리가 필요하다면 추가 (예: webp-devel, lcms2-devel, tcl-devel, tk-devel, openjp2-devel 등)
    # 현재 `Pillow`만이라면 위 4-5개만으로 충분할 가능성이 높습니다.
    && yum clean all \
    && rm -rf /var/cache/yum

WORKDIR /var/task

# requirements.txt 파일이 있다면 먼저 COPY합니다.
COPY requirements.txt .
# pip3 install pillow -t . # <--- 이 라인을 삭제하고 아래와 같이 수정합니다.

# requirements.txt에 있는 모든 파이썬 의존성을 설치합니다.
# Pillow도 requirements.txt에 있다면 이 명령으로 설치됩니다.
RUN pip3 install -r requirements.txt -t .

COPY lambda_function.py .

# 빌드 캐시를 줄이기 위해 불필요한 파일 삭제 (선택 사항)
RUN find . -type f -name "*.pyc" -delete && \
    find . -type d -name "__pycache__" -delete

# lambda_function.zip 생성 (도커 이미지 자체가 아니라 zip 파일을 S3에 올리는 용도)
# WORKDIR이 /var/task 이므로, 여기서 바로 압축하면 됩니다.
RUN zip -r /lambda_function.zip .