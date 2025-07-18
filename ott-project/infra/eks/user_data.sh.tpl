#!/bin/bash
set -o xtrace

# EKS 노드 설정
/etc/eks/bootstrap.sh ${cluster_name} \
  --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=ott-node-group-v7' \
  --apiserver-endpoint ${cluster_endpoint} \
  --b64-cluster-ca ${cluster_ca_certificate}

# 시스템 최적화
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" >> /etc/sysctl.conf
sysctl -p

# Docker 데몬 최적화
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker