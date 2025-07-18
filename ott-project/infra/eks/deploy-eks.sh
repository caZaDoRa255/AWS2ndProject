#!/bin/bash

# EKS 클러스터 배포 스크립트
set -e

echo "=== EKS 클러스터 배포 시작 ==="

# 1. Terraform 초기화
echo "1. Terraform 초기화 중..."
terraform init

# 2. Terraform 계획 확인
echo "2. Terraform 계획 확인 중..."
terraform plan

# 3. Terraform 적용
echo "3. Terraform 적용 중..."
terraform apply -auto-approve

# 4. 배포 완료 대기
echo "4. EKS 클러스터 생성 완료 대기 중..."
echo "이 과정은 약 10-15분이 소요됩니다."

# 5. 클러스터 상태 확인
echo "5. 클러스터 상태 확인 중..."
aws eks describe-cluster --region ap-northeast-2 --name ott-eks --query 'cluster.status'

echo "=== EKS 클러스터 배포 완료 ==="
echo "이제 Bastion EC2에서 connect-to-eks.sh 스크립트를 실행하여 클러스터에 접근할 수 있습니다." 