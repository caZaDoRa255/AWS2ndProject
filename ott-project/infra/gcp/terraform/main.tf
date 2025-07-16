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

# Google 클라이언트 설정 (Helm provider용)
data "google_client_config" "default" {}

# GKE 클러스터 생성 후 kubectl 인증 설정
resource "null_resource" "configure_kubectl" {
  depends_on = [google_container_cluster.gke, google_container_node_pool.primary_nodes]

  triggers = {
    cluster_endpoint = google_container_cluster.gke.endpoint
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.gke_cluster_name} --region ${var.gke_location} --project ${var.project_id}"
  }
}

# Kubernetes provider 설정 (GKE 클러스터 생성 후)
provider "kubernetes" {
  alias = "gke"
  host  = "https://${google_container_cluster.gke.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  token = data.google_client_config.default.access_token
}

# -----------------------------------
# 프로젝트 번호 가져오기 (Cloud Build 서비스 계정 이메일 구성용)
# # -----------------------------------
# data "google_project" "project" {
#   project_id = var.project_id
# }


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

resource "google_compute_firewall" "allow_https_gke" {
  name    = "allow-https-gke"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]

  # GKE 노드에 적용되는 태그
  target_tags = ["gke-${var.gke_cluster_name}-node"]
}


# -----------------------------------
# GCP VM 방화벽 규칙 추가
# (이 규칙은 AWS Lambda에서 GCP VM으로 들어오는 HTTP/HTTPS 트래픽을 허용합니다)
# -----------------------------------
resource "google_compute_firewall" "allow_aws_lambda_to_fastapi" {
  name        = "allow-aws-lambda-to-fastapi-backend"
  # ✅ `var.vpc_name`을 사용하여 네트워크를 참조합니다.
  # 당신의 `variables.tf`에 `vpc_name`이 있으므로, `google_compute_network.custom_vpc.self_link` 대신
  # `var.vpc_name`으로 정의된 네트워크 리소스의 self_link를 사용하는 것이 깔끔합니다.
  # (만약 `google_compute_network` 리소스 이름이 "custom_vpc"라면, `google_compute_network.custom_vpc.self_link`가 맞습니다.)
  # 여기서는 `vpc_name` 변수를 통해 해당 네트워크 리소스를 참조하는 일반적인 방식을 사용하겠습니다.

  network     = "projects/${var.project_id}/global/networks/${var.vpc_name}" # ✅ 당신의 GCP VPC 네트워크 이름 참조

  # ✅ 인바운드 (INGRESS) 규칙: AWS Lambda에서 들어오는 HTTP/HTTPS 트래픽 허용
  allow {
    protocol = "tcp"
    ports    = ["80", "443"] # FastAPI 백엔드가 HTTP(80) 또는 HTTPS(443)로 서비스된다면
  }

  # ✅ 소스 IP 범위: AWS VPC의 프라이빗 CIDR 블록
  # 이 값은 AWS Terraform 프로젝트에서 `terraform.tfvars`에 정의했던 `gcp_vpc_private_cidr_block`과
  # 동일한 값을 가지는 **AWS VPC의 실제 CIDR**입니다.
  source_ranges = var.aws_vpc_private_cidr_blocks_for_gcp_firewall # ✅ 이 변수는 `gcp` var.tf에 새로 정의할 겁니다.

  # ✅ 타겟 태그: 이 방화벽 규칙을 적용할 GCP VM에 붙일 태그
  # 이 태그를 FastAPI 백엔드가 실행되는 VM(private_vm)에 추가해야 합니다.
  target_tags = ["fastapi-backend"]

  direction = "INGRESS" # 인바운드 (들어오는) 트래픽에 적용
  priority  = 1000      # 규칙의 우선순위 (낮을수록 우선)
  description = "Allow inbound HTTP/HTTPS from AWS Lambda via VPN."
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
  
  # GKE 노드를 위한 추가 설정
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
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
# 퍼블릭 VM 인스턴스 (FastAPI 백엔드를 배포하지 않을 것이라면, 
# public_vm에 대한 Terraform 코드를 따로 수정할 필요가 없다)
# -----------------------------------
# 만약 public_vm에 FastAPI 백엔드가 있다면, 위에 정의된 방화벽 규칙을
# public_vm에도 적용하려면 public_vm의 tags에도 "fastapi-backend"를 추가해야 합니다.
# 그렇지 않다면 이 부분은 변경하지 않아도 됩니다.
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
    access_config {} # 외부 IP 부여됨
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
# 프라이빗 VM 인스턴스 (수정)
# -----------------------------------
resource "google_compute_instance" "private_vm" {
  name         = var.private_vm_name
  machine_type = "e2-micro"
  zone         = var.zone

  # ✅ 'fastapi-backend' 태그 추가
  # 이 태그를 통해 위에 정의된 방화벽 규칙이 이 VM에 적용됩니다.
  tags = ["icmp-enabled", "ssh-enabled", "fastapi-backend"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No access_config → no external IP (private VM이므로 변경 없음)
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


# --- Cloud SQL Private IP를 위한 필수 구성 요소 ---

# 1. Service Networking API 활성화 (프로젝트당 1회)
# Cloud SQL Private IP를 사용하려면 이 API가 활성화되어야 합니다.
# 이미 활성화되어 있다면 Terraform은 이 리소스를 건너뜁니다.
resource "google_project_service" "servicenetworking" {
  service            = "servicenetworking.googleapis.com"
  project            = var.project_id # ✅ 기존 project_id 변수 사용
  disable_on_destroy = false
}

#  올바른 IP Range를 위한 리소스를 먼저 생성해야 함
# 아래처럼 google_compute_global_address를 먼저 정의해줘야 GCP가 해당 IP를 "예약된 Peering 범위"로 인식합니다.
resource "google_compute_global_address" "sql_private_ip_range" {
  name          = "sql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.vpc_network.id
}

# 2. Cloud SQL Private IP를 위한 Service Networking Connection 생성
# 당신의 GCP VPC 네트워크와 Google의 서비스 네트워크(Cloud SQL이 속한) 간의 연결 통로를 만듭니다.
# 이 통로를 통해 당신의 GCP VM이 Cloud SQL에 프라이빗 IP로 접근할 수 있습니다.
resource "google_service_networking_connection" "sql_private_connection" {
  network                 = google_compute_network.vpc_network.id # ✅ 당신의 VPC 이름을 참조
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip_range.name]
  depends_on              = [google_project_service.servicenetworking]
}


# --- Cloud SQL 인스턴스 수정 (기존 리소스) ---
resource "google_sql_database_instance" "mysql_instance" {
  name             = var.instance_name
  database_version = "MYSQL_8_0"
  region           = var.region

  deletion_protection = false

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      private_network = google_compute_network.vpc_network.id
      ipv4_enabled = false
      # authorized_networks {
      #   name  = "allow-all"
      #   value = "0.0.0.0/0"
      # }
    }
    #자동 백업
    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      location           = "us" # 백업 저장 위치 (리전위치 작성)
      binary_log_enabled = true # MySQL PITR 활성화
      #예: 실수로 오늘 11:34에 데이터를 삭제했다면, 11:33으로 되돌리기 가능!
      transaction_log_retention_days = 7   # 트랜잭션 로그 보관일수
    }
  }

  # ✅ resource 블록의 최상위에 depends_on을 위치시킵니다!
  depends_on = [
    google_service_networking_connection.sql_private_connection
  ]
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

# resource "google_project_service" "cloudbuild" {
#   project                    = var.project_id
#   service                    = "cloudbuild.googleapis.com"
#   disable_dependent_services = true # 추가
#   disable_on_destroy = false
# }

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

# resource "google_project_service" "cloudfunctions_api" {
#   project = var.project_id
#   service = "cloudfunctions.googleapis.com"
#   disable_on_destroy = false
# }

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
# resource "google_project_iam_member" "cloud_build_artifact_registry_writer" {
#   project = var.project_id
#   role    = "roles/artifactregistry.writer"
#   member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

#   depends_on = [
#     google_project_service.artifactregistry,
#     google_project_service.cloudbuild
#   ]
# }

# resource "google_project_iam_member" "cloud_build_functions_developer" {
#   project = var.project_id
#   role    = "roles/cloudfunctions.developer"
#   member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

#   depends_on = [
#     google_project_service.cloudfunctions,
#     google_project_service.cloudbuild
#   ]
# }

# resource "google_project_iam_member" "cloud_build_sa_user" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

#   depends_on = [
#     google_project_service.iam,
#     google_project_service.cloudbuild
#   ]
# }

# resource "google_project_iam_member" "cloud_build_run_admin" {
#   project = var.project_id
#   role    = "roles/run.admin"
#   member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

#   depends_on = [
#     google_project_service.cloudrun,
#     google_project_service.cloudbuild
#   ]
# }

# #---------------------------------------------------------
# # Cloud Functions 런타임 서비스 계정 (기본: Compute Engine 기본 서비스 계정)에 필요한 권한 부여
# # 이 서비스 계정은 [PROJECT_NUMBER]-compute@developer.gserviceaccount.com 형태입니다.
# resource "google_project_iam_member" "functions_runtime_run_invoker" {
#   project = var.project_id
#   role    = "roles/run.invoker"
#   member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

#   depends_on = [
#     google_project_service.cloudrun,
#     google_project_service.cloudfunctions
#   ]
# }

# resource "google_project_iam_member" "functions_runtime_run_developer" {
#   project = var.project_id
#   role    = "roles/run.developer"
#   member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

#   depends_on = [
#     google_project_service.cloudrun,
#     google_project_service.cloudfunctions
#   ]
# }


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

# resource "google_storage_bucket" "function_bucket" {
#   name     = "${var.project_id}-function-bucket"
#   location = var.region
# }

# resource "google_storage_bucket_object" "function_zip" {
#   name   = "function-source.zip"
#   bucket = google_storage_bucket.function_bucket.name
#   source = "${path.module}/function-source.zip"
# }

# Cloud Functions 서비스 에이전트에 Artifact Registry Reader 권한 부여
# resource "google_project_iam_member" "cloud_functions_artifact_reader" {
#   project = var.project_id
#   role    = "roles/artifactregistry.reader"
#   member  = "serviceAccount:service-291577203787@gcf-admin-robot.iam.gserviceaccount.com" # <YOUR_PROJECT_NUMBER>를 실제 프로젝트 번호로 변경
# }

# resource "google_cloudfunctions2_function" "hello_function" {
#   provider = google-beta
#   name     = "hello-function"
#   location = var.region

#   build_config {
#     runtime     = "python310"
#     entry_point = "hello_world"
    
#     source {
#       storage_source {
#         bucket = google_storage_bucket.function_bucket.name
#         object = google_storage_bucket_object.function_zip.name
#       }
#     }
#   }


#   service_config {
#     available_memory = "128Mi"
#     timeout_seconds  = 60
#     ingress_settings = "ALLOW_ALL"
#     environment_variables = {
#       ENV = "dev"
#     }
#     service_account_email = "terraform-vm-sa@ott-project-462006.iam.gserviceaccount.com" 
#   }


#   depends_on = [
#       google_project_service.cloudfunctions,
#       google_project_service.cloudbuild,
#       google_project_service.storage,
#       google_project_service.artifactregistry, # Artifact Registry API 활성화 대기
#       google_project_service.cloudrun,        # Cloud Run API 활성화 대기
#       google_project_iam_member.cloud_build_artifact_registry_writer, # 권한 부여 대기
#       google_project_iam_member.cloud_build_functions_developer,
#       google_project_iam_member.cloud_build_sa_user,
#       google_project_iam_member.cloud_build_run_admin,
#       google_project_iam_member.functions_runtime_run_invoker,
#       google_project_iam_member.functions_runtime_run_developer,
#       google_project_iam_member.cloud_functions_artifact_reader
#   ]
# }


# Cloud Functions (2세대) HTTP 트리거에 대한 접근 권한 설정
# allUsers가 함수를 호출할 수 있도록 'roles/run.invoker' 부여
# resource "google_cloud_run_service_iam_member" "invoker" {
#   provider = google-beta
#   location = var.region
#   service  = google_cloudfunctions2_function.hello_function.service_config[0].service
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }




#------------------------------------------------
#API Gateway resource

# resource "google_api_gateway_api" "hello_api" {
#   provider = google-beta
#   api_id = "hello-api"
#   project  = var.project_id

#   depends_on = [google_project_service.api_gateway]
# }


# resource "google_api_gateway_api_config" "hello_config" {
#   provider = google-beta
#   api      = google_api_gateway_api.hello_api.api_id
#   display_name = "hello-config"

# openapi_documents {
#   document {
#     path     = "openapi-dynamic.yml"
#     contents = base64encode(data.template_file.openapi.rendered)
#   }
# }

# project = var.project_id

# }

# data "template_file" "openapi" {
#   template = file("${path.module}/../../../manifests/k8s/openapi.tpl.yml")
#   vars = {
#     cloud_function_url = google_cloudfunctions2_function.hello_function.service_config[0].uri
#   }
# }


# resource "google_api_gateway_gateway" "hello_gateway" {
#   gateway_id        = "hello-gateway"
#   project      = var.project_id
#   provider = google-beta
#   api_config  = google_api_gateway_api_config.hello_config.id
#   region      = "us-central1"

#   depends_on = [
#     google_project_service.api_gateway,
#     google_api_gateway_api_config.hello_config,
#     google_project_iam_member.terraform_api_gateway_editor # 권한 부여 대기
#   ]
# }

# output "api_gateway_url" {
#   description = "The URL of the deployed API Gateway"
#   value       = google_api_gateway_gateway.hello_gateway.default_hostname
# }

# Harbor 설치는 harbor.tf에서 관리됨

