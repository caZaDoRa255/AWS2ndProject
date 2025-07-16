resource "google_compute_firewall" "allow_gke_to_cloudsql" {
  name    = "allow-gke-to-cloudsql"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  # GKE 노드에 붙는 네트워크 태그 (클러스터 생성 시 자동 부여)
  source_tags = ["gke-${var.gke_cluster_name}-node"]

  # Cloud SQL 인스턴스의 내부 IP 대역 (CIDR)
  destination_ranges = [var.cloudsql_private_ip_cidr]

  direction = "INGRESS"
  priority  = 1000
  description = "Allow GKE nodes to access Cloud SQL via private IP on port 3306."
} 