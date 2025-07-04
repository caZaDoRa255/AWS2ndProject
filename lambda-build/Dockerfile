FROM amazonlinux:2

RUN yum install -y python3 zip
WORKDIR /var/task

RUN pip3 install pillow -t .
COPY lambda_function.py .
RUN zip -r /lambda_function.zip .