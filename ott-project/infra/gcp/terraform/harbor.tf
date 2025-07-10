# Harbor 자동 설치 (Windows PowerShell 호환)
resource "null_resource" "install_harbor" {
  depends_on = [google_container_cluster.gke, google_container_node_pool.primary_nodes]

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command = <<-EOT
      Write-Host "🚢 Harbor 설치 시작..."
      
      # Helm repository 추가
      helm repo add harbor https://helm.goharbor.io
      helm repo update
      
      # Harbor 네임스페이스 생성
      kubectl create namespace harbor-system --dry-run=client -o yaml | kubectl apply -f -
      
      # Harbor 설치
      helm install harbor harbor/harbor `
        --namespace harbor-system `
        --set expose.type=clusterIP `
        --set expose.tls.enabled=false `
        --set harborAdminPassword="${var.harbor_admin_password}" `
        --set persistence.enabled=true `
        --set persistence.persistentVolumeClaim.registry.size=5Gi `
        --set persistence.persistentVolumeClaim.chartmuseum.size=5Gi `
        --set persistence.persistentVolumeClaim.jobservice.size=1Gi `
        --set persistence.persistentVolumeClaim.database.size=1Gi `
        --set persistence.persistentVolumeClaim.redis.size=1Gi `
        --set persistence.persistentVolumeClaim.trivy.size=5Gi
      
      # Harbor 배포 대기
      Write-Host "⏳ Harbor 배포 대기 중..."
      kubectl wait --for=condition=ready pod -l app=harbor -n harbor-system --timeout=600s
      
      # Harbor 서비스 정보 출력
      $HARBOR_IP = kubectl get svc harbor-harbor-core -n harbor-system -o jsonpath='{.spec.clusterIP}'
      Write-Host "✅ Harbor 설치 완료!"
      Write-Host "🌐 Harbor URL: http://$HARBOR_IP"
      Write-Host "👤 관리자 계정: admin / [비밀번호는 변수에서 설정됨]"
      Write-Host "📝 이미지 주소: http://$HARBOR_IP/harbor"
    EOT
  }
}

output "harbor_internal_ip" {
  description = "Harbor 내부 IP 주소"
  value       = "http://harbor-harbor-core.harbor-system.svc.cluster.local"
  depends_on  = [null_resource.install_harbor]
}

output "harbor_admin_password" {
  description = "Harbor 관리자 비밀번호"
  value       = var.harbor_admin_password
  sensitive   = true
}