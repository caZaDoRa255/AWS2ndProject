resource "google_container_cluster" "gke" {
  name     = var.gke_cluster_name
  location = var.gke_location

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.private_subnet.self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pod-range"
    services_secondary_range_name = "gke-svc-range"
  }

  deletion_protection = false

  # 마스터 인증 네트워크 설정
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "my-ip"
      cidr_block = var.my_ip
    }
  }

  # 기본 노드 풀 설정 (제거됨)
  remove_default_node_pool = true
  initial_node_count = 1

  # 클러스터 설정
  enable_legacy_abac = false

  # GCE Ingress Controller(HTTP Load Balancing) 활성화
  addons_config {
    http_load_balancing {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.gke_location
  cluster    = google_container_cluster.gke.name
  node_count = var.gke_node_count

  node_config {
    disk_size_gb = 20
    machine_type = "e2-small"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/compute",
    ]
    # 기본 서비스 계정 사용
    service_account = "default"
  }
}






