# -----------------------------------
# Provider 설정
# -----------------------------------
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)  # 서비스 계정 키 JSON
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# -----------------------------------
# 프로젝트 번호 가져오기 (Cloud Build 서비스 계정 이메일 구성용)
# -----------------------------------
data "google_project" "project" {
  project_id = var.project_id
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

  secondary_ip_range {
    range_name    = "gke-pod-range"
    ip_cidr_range = "10.11.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-svc-range"
    ip_cidr_range = "10.12.0.0/20"
  }
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


# -----------------------------------
# Cloud sql
# -----------------------------------
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

resource "google_sql_database" "app_db" {
  name     = "app_db"
  instance = google_sql_database_instance.mysql_instance.name
  charset  = "utf8mb4"
  collation = "utf8mb4_general_ci"
}


resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.mysql_instance.name
  password = var.db_password
  host= "%"
}


#---------------------------------------------------------
# 필수 API 사용 설정 (권한 문제 해결을 위해 Artifact Registry 및 Cloud Run API 추가)

resource "google_project_service" "api_gateway" {
  project                    = var.project_id
  service                    = "apigateway.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project                    = var.project_id
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project                    = var.project_id
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project                    = var.project_id
  service                    = "storage.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  project                    = var.project_id
  service                    = "eventarc.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  project                    = var.project_id
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

# Artifact Registry API 활성화
resource "google_project_service" "artifactregistry" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

# Cloud Run API 활성화
resource "google_project_service" "cloudrun" {
  project                    = var.project_id
  service                    = "run.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
}

# IAM API 활성화 (서비스 계정 권한 관리를 위해)
resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_dependent_services = true # 추가
  disable_on_destroy = false
  
}

resource "google_project_service" "cloudfunctions_api" {
  project = "ott-project-462006" # 실제 프로젝트 ID로 변경하세요.
  service = "cloudfunctions.googleapis.com"
  disable_dependent_services = true 
  disable_on_destroy = false
}

# 이 리소스는 특정 GCP 서비스 API를 활성화합니다.
resource "google_project_service" "container_api" {
  project = "ott-project-462006"
  service = "container.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy = false
    # Kubernetes Engine API가 활성화될 때까지 기다리도록 의존성 추가
  depends_on = [
  google_project_service.container_api
  ] 
}

#---------------------------------------------------------
# Cloud Build 서비스 계정에 필요한 권한 부여 (Cloud Functions 빌드 성공을 위해 추가)
# 이 서비스 계정은 [PROJECT_NUMBER]@cloudbuild.gserviceaccount.com 형태입니다.
resource "google_project_iam_member" "cloud_build_artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.artifactregistry,
    google_project_service.cloudbuild
  ]
}

resource "google_project_iam_member" "cloud_build_functions_developer" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild
  ]
}

resource "google_project_iam_member" "cloud_build_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.iam,
    google_project_service.cloudbuild
  ]
}

resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudrun,
    google_project_service.cloudbuild
  ]
}

#---------------------------------------------------------
# Cloud Functions 런타임 서비스 계정 (기본: Compute Engine 기본 서비스 계정)에 필요한 권한 부여
# 이 서비스 계정은 [PROJECT_NUMBER]-compute@developer.gserviceaccount.com 형태입니다.
resource "google_project_iam_member" "functions_runtime_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudrun,
    google_project_service.cloudfunctions
  ]
}

resource "google_project_iam_member" "functions_runtime_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudrun,
    google_project_service.cloudfunctions
  ]
}


# -----------------------------------
# Terraform 실행 서비스 계정(credential 파일에 명시된 계정)에 API Gateway Editor 역할 부여
# 이 역할은 API Gateway, API Config, Gateway 리소스 생성/관리에 필요한 권한을 포함합니다.
# --- [필수 수정] Terraform 실행 서비스 계정 이메일 ---
# `var.credentials_file`에 명시된 서비스 계정의 이메일을 정확히 입력하세요.
# 예: member = "serviceAccount:my-terraform-sa@my-project-id.iam.gserviceaccount.com"
# 만약 개인 Google 계정으로 Terraform을 실행한다면 (권장되지 않음), "user:your-email@example.com" 형식으로 입력합니다.
resource "google_project_iam_member" "terraform_api_gateway_editor" {
  project = var.project_id
  role    = "roles/apigateway.admin"
  member  = "serviceAccount:terraform-vm-sa@ott-project-462006.iam.gserviceaccount.com" # <--- 이 부분을 사용자 서비스 계정 이메일로 수정하세요!
  
  depends_on = [
    google_project_service.api_gateway, # API Gateway API 활성화 대기
    google_project_service.iam          # IAM API 활성화 대기
  ]
}




#---------------------------------------------------------
#cloud function2 (HTTP트리거) 

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/function-source.zip"
}

# Cloud Functions 서비스 에이전트에 Artifact Registry Reader 권한 부여
resource "google_project_iam_member" "cloud_functions_artifact_reader" {
  project = "ott-project-462006" # 실제 프로젝트 ID로 변경하세요
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-291577203787@gcf-admin-robot.iam.gserviceaccount.com" # <YOUR_PROJECT_NUMBER>를 실제 프로젝트 번호로 변경
}

resource "google_cloudfunctions2_function" "hello_function" {
  provider = google-beta
  name     = "hello-function"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "hello_world"
    
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }


  service_config {
    available_memory = "128Mi"
    timeout_seconds  = 60
    ingress_settings = "ALLOW_ALL"
    environment_variables = {
      ENV = "dev"
    }
    service_account_email = "terraform-vm-sa@ott-project-462006.iam.gserviceaccount.com" 
  }


  depends_on = [
      google_project_service.cloudfunctions,
      google_project_service.cloudbuild,
      google_project_service.storage,
      google_project_service.artifactregistry, # Artifact Registry API 활성화 대기
      google_project_service.cloudrun,        # Cloud Run API 활성화 대기
      google_project_iam_member.cloud_build_artifact_registry_writer, # 권한 부여 대기
      google_project_iam_member.cloud_build_functions_developer,
      google_project_iam_member.cloud_build_sa_user,
      google_project_iam_member.cloud_build_run_admin,
      google_project_iam_member.functions_runtime_run_invoker,
      google_project_iam_member.functions_runtime_run_developer,
      google_project_iam_member.cloud_functions_artifact_reader
  ]
}


# Cloud Functions (2세대) HTTP 트리거에 대한 접근 권한 설정
# allUsers가 함수를 호출할 수 있도록 'roles/run.invoker' 부여
resource "google_cloud_run_service_iam_member" "invoker" {
  provider = google-beta
  location = var.region
  service  = google_cloudfunctions2_function.hello_function.service_config[0].service
  role     = "roles/run.invoker"
  member   = "allUsers"
}




#------------------------------------------------
#API Gateway resource

resource "google_api_gateway_api" "hello_api" {
  provider = google-beta
  api_id = "hello-api"
  project  = var.project_id

  depends_on = [google_project_service.api_gateway]
}


resource "google_api_gateway_api_config" "hello_config" {
  provider = google-beta
  api      = google_api_gateway_api.hello_api.api_id
  display_name = "hello-config"

openapi_documents {
  document {
    path     = "openapi-dynamic.yml"
    contents = base64encode(data.template_file.openapi.rendered)
  }
}

project = var.project_id

depends_on = [google_cloudfunctions2_function.hello_function]

}

data "template_file" "openapi" {
  template = file("${path.module}/../../../manifests/k8s/openapi.tpl.yml")
  vars = {
    cloud_function_url = google_cloudfunctions2_function.hello_function.service_config[0].uri
  }
}


resource "google_api_gateway_gateway" "hello_gateway" {
  gateway_id        = "hello-gateway"
  project      = var.project_id
  provider = google-beta
  api_config  = google_api_gateway_api_config.hello_config.id
  region      = "us-central1"

  depends_on = [
    google_project_service.api_gateway,
    google_api_gateway_api_config.hello_config,
    google_project_iam_member.terraform_api_gateway_editor # 권한 부여 대기
  ]
}

output "api_gateway_url" {
  description = "The URL of the deployed API Gateway"
  value       = google_api_gateway_gateway.hello_gateway.default_hostname
}