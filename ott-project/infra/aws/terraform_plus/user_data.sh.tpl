#!/bin/bash

ACCESS_KEY="${ACCESS_KEY}"
SECRET_KEY="${SECRET_KEY}"


# AWS CLI configure
sudo -u ec2-user aws configure set aws_access_key_id "${ACCESS_KEY}" --profile admin
sudo -u ec2-user aws configure set ***REMOVED*** "${SECRET_KEY}" --profile admin
sudo -u ec2-user aws configure set region ap-northeast-2 --profile admin

# Create bin directory and move kubectl there
sudo -u ec2-user mkdir -p /home/ec2-user/bin

# Download kubectl
sudo curl -O  https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl

# File Move
sudo mv /kubectl /home/ec2-user/bin/kubectl 

# Make kubectl executable
sudo chown ec2-user:ec2-user /home/ec2-user/bin/kubectl
sudo chmod +x /home/ec2-user/bin/kubectl

# Update kubeconfig for EKS
sudo -u ec2-user aws eks update-kubeconfig --region ap-northeast-2 --name ott-eks --profile admin

#-----------------------------------------------------------------------------------------------------


# Argo CD 설치 자동화

# Argo CD namespace 생성
sudo -u ec2-user /home/ec2-user/bin/kubectl create namespace argocd

# Argo CD 설치
sudo -u ec2-user /home/ec2-user/bin/kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Argo CD 서버 서비스 타입 LoadBalancer로 변경
sudo -u ec2-user /home/ec2-user/bin/kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "🎉 Argo CD 설치 완료. 잠시 후 LoadBalancer 주소가 발급됩니다."



#-------------------------------------------------------------------

# ott-project-app.yml 생성
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
    # 제가 path 고쳤어요 잘했죠?
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF


# 적용
sudo -u ec2-user /home/ec2-user/bin/kubectl apply -f /home/ec2-user/ott-project-app.yml -n argocd


