#!/bin/bash
set -o xtrace

# AWS CLI 설정
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[${PROFILE_NAME}]
aws_access_key_id = ${ACCESS_KEY}
aws_secret_access_key = ${SECRET_KEY}
region = ${AWS_REGION}
EOF

cat > ~/.aws/config <<EOF
[profile ${PROFILE_NAME}]
region = ${AWS_REGION}
output = json
EOF

# 시스템 업데이트
yum update -y
yum install -y docker git jq

# Docker 시작
systemctl start docker
systemctl enable docker

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# AWS CLI v2 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# EKS 클러스터 설정 (EKS가 배포된 후 사용)
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

# EKS 클러스터 상태 확인
aws eks describe-cluster --region ${AWS_REGION} --name ${CLUSTER_NAME}

echo "Bastion host setup completed!" 