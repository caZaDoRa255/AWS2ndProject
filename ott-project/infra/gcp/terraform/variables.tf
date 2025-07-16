variable "project_id" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "credentials_file" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = "custom-vpc"
}

variable "public_subnet_name" {
  type    = string
  default = "public-subnet"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "vm_name" {
  type    = string
  default = "demo-vm"
}

variable "bucket_name" {
  type = string
}

variable "private_subnet_name" {
  type    = string
  default = "private-subnet"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "private_vm_name" {
  type    = string
  default = "private-vm"
}

variable "gke_cluster_name" {
  default = "team4-gke"
}

variable "gke_location" {
  default = "us-central1-a"
}

variable "gke_node_count" {
  default = 2
}


variable "gke_service_account_email" {
  description = "클러스터 노드에 연결할 서비스 계정 이메일"
}

variable "gcp_region" {
  default = "us-central1"
}

# AWS 쪽 Customer Gateway의 퍼블릭 IP (vpn2.tf에서 사용)
# variable "aws_customer_gateway_ip" {
#   description = "Customer Gateway IP from AWS side"
#   type        = string
#   default     = ""
# }

# 양쪽이 공유하는 VPN 터널 비밀키 (vpn2.tf에서 사용)
# variable "vpn_shared_secret" {
#   description = "Shared secret used for VPN tunnel between AWS and GCP"
#   type        = string
#   sensitive   = true
#   default     = "your-vpn-shared-secret-here"
# }

# GCP 서브넷 CIDR (vpn2.tf에서 사용)
# variable "gcp_private_subnet_cidr" {
#   description = "CIDR block of the GCP private subnet"
#   type        = string
#   default     = "10.128.0.0/20"
# }

# AWS 서브넷 CIDR (라우팅용) (vpn2.tf에서 사용)
# variable "aws_private_subnet_cidr" {
#   description = "CIDR block of the AWS private subnet to route to"
#   type        = string
#   default     = "10.0.0.0/16"
# }


variable "instance_name" {
  default = "mydb"
}
variable "db_user" {
  default = "ott_admin"
}
variable "db_password" {}  # terraform.tfvars 또는 secret으로 주입
variable "db_name" {
  default = "app_db"
}

variable "my_ip" {
  description = "GKE API 서버에 접근할 수 있도록 허용할 IP"
  default     = "210.124.140.19/32"  
}

variable "gitlab_username" {
  type = string
}

variable "gitlab_token" {
  description = "GitLab Personal Access Token"
  type        = string
  sensitive   = false
}

variable "fastapi_image" {
  description = "FastAPI Docker 이미지 주소"
  type        = string
}

variable "aws_vpc_private_cidr_blocks_for_gcp_firewall" {
  description = "AWS VPC에서 GCP로 허용할 프라이빗 CIDR 블록"
  type        = list(string)
  default     = ["10.0.101.0/24"] # 실제 값으로 수정
}

variable "harbor_admin_password" {
  description = "Harbor 관리자 비밀번호"
  type        = string
  sensitive   = true
  default     = ""  # terraform.tfvars에서 설정
}

# FastAPI 환경변수 관련 변수들
variable "access_token_expire_minutes" {
  description = "Access token 만료 시간 (분)"
  type        = string
  default     = "60"
}

variable "refresh_token_expire_days" {
  description = "Refresh token 만료 시간 (일)"
  type        = string
  default     = "30"
}

variable "secret_key" {
  description = "FastAPI Secret Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "database_url" {
  description = "데이터베이스 연결 URL"
  type        = string
  default     = "mysql+pymysql://ott_admin:team4321@34.123.123.123:3306/app_db"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
  default     = ""
}

variable "gemini_api_key" {
  description = "Gemini API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "frontend_origin" {
  description = "프론트엔드 Origin URL"
  type        = string
  default     = "http://frontend.moodlyharbor.link"
}

variable "cloudsql_private_ip_cidr" {
  description = "Cloud SQL 인스턴스의 내부 IP 대역 (CIDR)"
  type        = string
}