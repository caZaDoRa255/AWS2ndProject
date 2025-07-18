# EKS 클러스터 배포 가이드

## 개요
이 디렉토리는 AWS EKS 클러스터를 Terraform으로 배포하기 위한 설정을 포함합니다.

## 아키텍처
- EKS 클러스터는 프라이빗 서브넷에 배포됩니다
- Bastion EC2를 통해 EKS 클러스터에 접근합니다
- VPC 엔드포인트를 통해 ECR 접근이 가능합니다

## 배포 방법

### 1. EKS 클러스터 배포
```bash
cd infra/eks
./deploy-eks.sh
```

### 2. Bastion EC2에서 EKS 접근
```bash
# Bastion EC2에 SSH 접속
ssh -i team4-key.pem ec2-user@<bastion-public-ip>

# EKS 클러스터 접근 스크립트 실행
./connect-to-eks.sh
```

## 주요 구성 요소

### EKS 클러스터
- 클러스터 이름: `ott-eks`
- 리전: `ap-northeast-2` (서울)
- 서브넷: 프라이빗 서브넷

### 노드 그룹
- 인스턴스 타입: `t3.medium`
- 최소 노드: 1개
- 최대 노드: 3개
- 원하는 노드: 2개

### 보안 그룹
- EKS 노드 보안 그룹: Bastion에서 SSH 접근 허용
- VPC 엔드포인트 보안 그룹: ECR 접근용

## 문제 해결

### 노드 그룹 생성 실패 시
1. IAM 권한 확인
2. 서브넷 태그 확인
3. 보안 그룹 설정 확인
4. VPC 엔드포인트 상태 확인

### Bastion에서 접근 불가 시
1. Bastion 보안 그룹에서 SSH 허용 확인
2. EKS 노드 보안 그룹에서 Bastion 접근 허용 확인
3. 키 페어 설정 확인

## 파일 구조
- `eks.tf`: EKS 클러스터 및 노드 그룹 설정
- `eks_iam.tf`: IAM 역할 및 정책 설정
- `irsa.tf`: IRSA (IAM Roles for Service Accounts) 설정
- `variables.tf`: 변수 정의
- `outputs.tf`: 출력 값 정의
- `deploy-eks.sh`: 배포 스크립트
- `connect-to-eks.sh`: EKS 접근 스크립트 