# FROM amazonlinux:2
# Runtime.ImportModuleError 이런 오류가 나서 람다에서 설정한 파이썬버전이랑 같게 작성함

FROM public.ecr.aws/lambda/python:3.11
# AWS에서 공식적으로 제공하는 AWS ECR(Elastic Container Registry) Public Gallery에 호스팅된 이미지

RUN yum install -y python3 zip
WORKDIR /var/task

RUN pip3 install pillow -t .
COPY lambda_function.py .
RUN zip -r /lambda_function.zip .