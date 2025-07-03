resource "google_container_cluster" "gke" {
  name     = var.gke_cluster_name
  location = var.gke_location

  # enable_autopilot = true  # Autopilot 비활성화

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.private_subnet.self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pod-range"
    services_secondary_range_name = "gke-svc-range"
  }

  deletion_protection = false

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "my-ip"
      cidr_block = var.my_ip
    }
  }

  # Standard 모드에서 노드 풀 설정
  node_config {
    disk_size_gb = 20
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  # 초기 노드 풀 설정
  initial_node_count = 1
}

resource "null_resource" "get_gke_credentials" {
  depends_on = [google_container_cluster.gke]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.gke_cluster_name} --region ${var.gke_location} --project ${var.project_id}"
  }
}




