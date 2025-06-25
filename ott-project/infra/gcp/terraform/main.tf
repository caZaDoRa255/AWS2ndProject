# -----------------------------------
# Provider 설정
# -----------------------------------
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)  # 서비스 계정 키 JSON
}

# -----------------------------------
# VPC 네트워크
# -----------------------------------
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# -----------------------------------
# 퍼블릭 서브넷
# -----------------------------------
resource "google_compute_subnetwork" "public_subnet" {
  name          = var.public_subnet_name
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# -----------------------------------
# 프라이빗 서브넷
# -----------------------------------
resource "google_compute_subnetwork" "private_subnet" {
  name          = var.private_subnet_name
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

# -----------------------------------
# 방화벽 - SSH 허용
# -----------------------------------
resource "google_compute_firewall" "ssh_allow" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

#-----------------------------------
#IMCP 허용 방화벽 규칙
#-----------------------------------
resource "google_compute_firewall" "allow-icmp" {
  name    = "allow-icmp"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]  # 또는 내부망만 허용하려면 ["10.0.0.0/16"]
  target_tags   = ["icmp-enabled"]
}


# -----------------------------------
# Cloud NAT 설정을 위한 라우터
# -----------------------------------
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.name
  region  = var.region
}

# -----------------------------------
# Cloud NAT
# -----------------------------------
resource "google_compute_router_nat" "cloud_nat" {
  name                               = "cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# -----------------------------------
# 서비스 계정
# -----------------------------------
resource "google_service_account" "vm_service_account" {
  account_id   = "vm-access-sa"
  display_name = "Service account for private VM"
}

resource "google_project_iam_member" "gcs_access" {
  project = var.project_id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.vm_service_account.email}"

  depends_on = [google_service_account.vm_service_account]
}

resource "google_project_iam_member" "gke_sa_node" {
  project = var.project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${var.gke_service_account_email}"
}

resource "google_project_iam_member" "gke_sa_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${var.gke_service_account_email}"
}

resource "google_project_iam_member" "gke_sa_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.gke_service_account_email}"
}

resource "google_project_iam_member" "gke_sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.gke_service_account_email}"
}

# -----------------------------------
# 퍼블릭 VM 인스턴스
# -----------------------------------
resource "google_compute_instance" "public_vm" {
  name         = "demo-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  

  tags = ["ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id

    access_config {}  # 외부 IP 부여됨
  }

  
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y curl wget
    echo "Public VM is ready"
  EOT

  
  metadata = {
    ssh-keys = "gcp-user:${file("~/.ssh/team4-gcp-key.pub")}"
  }
}



# -----------------------------------
# 프라이빗 VM 인스턴스
# -----------------------------------
resource "google_compute_instance" "private_vm" {
  name         = var.private_vm_name
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["icmp-enabled","ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No access_config → no external IP
  }

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y curl wget unzip gnupg google-cloud-sdk
    echo "Private VM ready with GCS access."
  EOT
}

# -----------------------------------
# 자동 시작/종료 스케줄 (예약 스케줄러 및 Cloud Function 또는 타스크 스케줄러는 별도 필요)
# -----------------------------------
# 참고: Terraform으로 GCP Schedule 관리하려면 Cloud Scheduler + Cloud Function을 사용해야 함
# 이는 별도 모듈로 구성하는 것이 일반적이므로, 여기에선 설명용 주석만 포함

# 예시: 자동 시작/종료는 다음 구조로 구성해야 함 (실제 리소스는 별도 구현 필요)
# 1. Cloud Scheduler → Pub/Sub → Cloud Function → VM start/stop API 호출
# 2. 또는 gcloud CLI + cronjob을 통해 수동 구성

# Terraform 내에서 직접 VM auto start/stop은 기본적으로 지원되지 않으므로, 위와 같은 외부 트리거 필요

# -----------------------------------
# Cloud Storage 버킷
# -----------------------------------
resource "google_storage_bucket" "storage_bucket" {
  name     = var.bucket_name
  location = var.region
}



resource "google_sql_database_instance" "mysql_instance" {
  name             = var.instance_name
  database_version = "MYSQL_8_0"
  region           = var.region

  deletion_protection = false  # 🔥 이 줄 추가

  settings {
    tier = "db-f1-micro"  # db-f1-micro는 비용을 줄이는 저사양 옵션

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.mysql_instance.name
  password = var.db_password
}

resource "google_sql_database" "app_db" {
  name     = var.db_name
  instance = google_sql_database_instance.mysql_instance.name
}
