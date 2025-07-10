#!/bin/bash
set -e

# 로그 함수 정의
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Harbor installation..."

# 시스템 정보 확인
log "Checking system information..."
uname -a
cat /etc/os-release

# 시스템 업데이트
log "Updating system packages..."
if command -v dnf &> /dev/null; then
    sudo dnf update -y || log "Warning: System update failed, continuing..."
else
    sudo yum update -y || log "Warning: System update failed, continuing..."
fi

# Docker 설치
log "Installing Docker..."
if command -v dnf &> /dev/null; then
    sudo dnf install -y docker || log "Warning: Docker install failed, trying alternative..."
    sudo dnf install -y libxcrypt-compat || log "Warning: libxcrypt-compat not available"
else
    sudo yum install -y docker || log "Warning: Docker install failed, trying alternative..."
fi

# Docker 서비스 시작 및 활성화
log "Starting and enabling Docker service..."
sudo systemctl start docker || log "Warning: Failed to start Docker service"
sudo systemctl enable docker || log "Warning: Failed to enable Docker service"
sudo usermod -aG docker ec2-user || log "Warning: Failed to add ec2-user to docker group"

# Docker 상태 확인
log "Checking Docker status..."
sudo systemctl status docker --no-pager || log "Warning: Docker service status check failed"

# Docker Compose 설치
log "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || log "Warning: Docker Compose download failed"
    sudo chmod +x /usr/local/bin/docker-compose || log "Warning: Failed to make docker-compose executable"
fi

# Docker Compose 버전 확인
log "Checking Docker Compose version..."
docker-compose --version || log "Warning: Docker Compose version check failed"

# Harbor 다운로드 및 압축 해제
log "Downloading Harbor..."
cd /opt
if [ ! -f "harbor-online-installer-v2.10.0.tgz" ]; then
    sudo wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz || log "Warning: Harbor download failed"
fi

if [ -f "harbor-online-installer-v2.10.0.tgz" ]; then
    sudo tar xvf harbor-online-installer-v2.10.0.tgz || log "Warning: Harbor extraction failed"
    cd harbor || log "Error: Failed to change to harbor directory"
else
    log "Error: Harbor download file not found"
    exit 1
fi

# harbor.yml 설정
log "Configuring Harbor..."
if [ -f "harbor.yml.tmpl" ]; then
    sudo cp harbor.yml.tmpl harbor.yml
    sudo sed -i "s/^hostname: .*/hostname: www.moodlyharbor.click/" harbor.yml
    echo "external_url: https://www.moodlyharbor.click" | sudo tee -a harbor.yml
    sudo sed -i '/^https:/,/^  private_key:/ s/^/#/' harbor.yml
    sudo sed -i '/^http:/,/^  port:/ s/^#//' harbor.yml
    sudo sed -i '/^  port:/ s/.*/  port: 80/' harbor.yml
    
    log "Harbor configuration file created:"
    sudo cat harbor.yml
else
    log "Error: harbor.yml.tmpl not found"
    exit 1
fi

# Harbor 설치
log "Installing Harbor..."
if [ -f "install.sh" ]; then
    sudo ./install.sh || log "Warning: Harbor installation completed with warnings"
    log "Harbor installation finished!"
else
    log "Error: install.sh not found"
    exit 1
fi

# 설치 후 상태 확인
log "Checking Harbor installation status..."
if command -v docker &> /dev/null; then
    sudo docker ps -a || log "Warning: Failed to check Docker containers"
fi

log "Harbor installation process completed!" 