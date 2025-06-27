resource "google_container_cluster" "gke" {
  name     = var.gke_cluster_name
  location = var.gke_location

  enable_autopilot = true  # ✅ Autopilot 모드 전환

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




