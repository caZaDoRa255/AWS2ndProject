resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gke_location

  enable_autopilot = true  # ✅ Autopilot 모드 전환

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.private_subnet.self_link

  ip_allocation_policy {}
}


