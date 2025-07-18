#!/bin/bash

# EKS 클러스터 접근 스크립트
# 이 스크립트는 Bastion EC2에서 실행해야 합니다.

set -e

# 변수 설정
CLUSTER_NAME="ott-eks"
AWS_REGION="ap-northeast-2"

echo "=== EKS 클러스터 접근 스크립트 ==="

# 1. AWS CLI 설정 확인
echo "1. AWS CLI 설정 확인 중..."
aws sts get-caller-identity

# 2. EKS 클러스터 상태 확인
echo "2. EKS 클러스터 상태 확인 중..."
aws eks describe-cluster --region $AWS_REGION --name $CLUSTER_NAME --query 'cluster.status'

# 3. kubeconfig 업데이트
echo "3. kubeconfig 업데이트 중..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# 4. 클러스터 연결 확인
echo "4. 클러스터 연결 확인 중..."
kubectl cluster-info

# 5. 노드 상태 확인
echo "5. 노드 상태 확인 중..."
kubectl get nodes

# 6. 네임스페이스 확인
echo "6. 네임스페이스 확인 중..."
kubectl get namespaces

echo "=== EKS 클러스터 접근 완료 ==="
echo "이제 kubectl 명령어를 사용할 수 있습니다."
echo "예: kubectl get pods --all-namespaces" 