provider "kubernetes" {
  # GKE 클러스터 정보를 직접 설정
  host                   = "https://${google_container_cluster.gke.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

# Google Cloud 인증 정보
data "google_client_config" "current" {}
