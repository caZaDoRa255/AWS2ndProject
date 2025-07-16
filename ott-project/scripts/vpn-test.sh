#!/bin/bash

echo "🔍 VPN 연결 상태 확인 중..."

# AWS VPN 연결 상태 확인
echo "📡 AWS VPN 연결 상태:"
aws ec2 describe-vpn-connections --region ap-northeast-2 --query 'VpnConnections[*].[VpnConnectionId,State,Type]' --output table

# GCP VPN 터널 상태 확인
echo "☁️ GCP VPN 터널 상태:"
gcloud compute vpn-tunnels list --region=us-central1 --format="table(name,status,peerIp,sharedSecret)"

# 네트워크 연결 테스트
echo "🌐 네트워크 연결 테스트:"

# AWS에서 GCP로의 연결 테스트
echo "AWS → GCP 연결 테스트:"
ping -c 3 34.55.195.186

# GCP에서 AWS로의 연결 테스트
echo "GCP → AWS 연결 테스트:"
ping -c 3 10.10.2.10

echo "✅ VPN 연결 상태 확인 완료!" 