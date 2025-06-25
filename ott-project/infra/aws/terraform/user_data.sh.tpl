#!/bin/bash

AWS_REGION="${AWS_REGION}"
CLUSTER_NAME="${CLUSTER_NAME}"
ACCOUNT_ID="${ACCOUNT_ID}"
ROLE_NAME="${ROLE_NAME}"
PROFILE_NAME="${PROFILE_NAME}"
ACCESS_KEY="${ACCESS_KEY}"
SECRET_KEY="${SECRET_KEY}"

# 환경 변수 등록
echo "export AWS_PROFILE=${PROFILE_NAME}" >> /home/ec2-user/.bashrc
echo "export PATH=/home/ec2-user/bin:\$PATH" >> /home/ec2-user/.bashrc
export AWS_PROFILE="${PROFILE_NAME}"
export PATH=/home/ec2-user/bin:$PATH

# kubectl 설치
mkdir -p /home/ec2-user/bin
curl -LO "https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /home/ec2-user/bin/kubectl
chown ec2-user:ec2-user /home/ec2-user/bin/kubectl

# AWS CLI Profile 구성
mkdir -p /home/ec2-user/.aws
cat <<EOF > /home/ec2-user/.aws/credentials
[${PROFILE_NAME}]
aws_access_key_id = ${ACCESS_KEY}
aws_secret_access_key = ${SECRET_KEY}
EOF

cat <<EOF > /home/ec2-user/.aws/config
[profile ${PROFILE_NAME}]
region = ${AWS_REGION}
output = json
EOF

chown -R ec2-user:ec2-user /home/ec2-user/.aws

# EKS ACTIVE 대기
echo "⏳ Waiting for EKS cluster to become ACTIVE..."
until [ "$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.status' --output text --profile ${PROFILE_NAME})" == "ACTIVE" ]; do
  echo "🔄 Cluster status is not ACTIVE yet. Waiting 10s..."
  sleep 10
done
echo "✅ Cluster is ACTIVE!"

# kubeconfig 구성
sudo -u ec2-user aws eks update-kubeconfig --name "${CLUSTER_NAME}" 
# ArgoCD 설치
sudo -u ec2-user /home/ec2-user/bin/kubectl create namespace argocd
sudo -u ec2-user /home/ec2-user/bin/kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo -u ec2-user /home/ec2-user/bin/kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo "🎉 Argo CD 설치 완료"

# Argo CD App: React 프론트엔드
cat <<EOF > /home/ec2-user/ott-project-app.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/caZaDoRa255/AWS2ndProject
    targetRevision: main
    path: ott-project/manifests/k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

sudo -u ec2-user /home/ec2-user/bin/kubectl apply -f /home/ec2-user/ott-project-app.yml -n argocd

# ALB Controller App 배포
cat <<EOF > /home/ec2-user/alb-controller-app.yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-load-balancer-controller
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://aws.github.io/eks-charts
    targetRevision: 1.13.2
    chart: aws-load-balancer-controller
    helm:
      values: |
        clusterName: ${CLUSTER_NAME}
        serviceAccount:
          create: true
          name: aws-load-balancer-controller
          annotations:
            eks.amazonaws.com/role-arn: "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
        image:
          repository: 602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller
        region: ${AWS_REGION}
        watchNamespace: ""
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

sudo -u ec2-user /home/ec2-user/bin/kubectl apply -f /home/ec2-user/alb-controller-app.yml -n argocd

echo "🎉 AWS Load Balancer Controller Argo CD Application 설치 완료"