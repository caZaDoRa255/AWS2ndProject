variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast3"
}

variable "zone" {
  type    = string
  default = "asia-northeast3-a"
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
  default = "asia-northeast3"  # 서울
}

variable "gke_node_count" {
  default = 2
}

variable "gke_node_machine_type" {
  default = "e2-medium"
}

variable "gke_service_account_email" {
  description = "클러스터 노드에 연결할 서비스 계정 이메일"
}

variable "gcp_region" {
  description = "Region for GCP resources"
  default     = "asia-northeast3"  
}

# AWS 쪽 Customer Gateway의 퍼블릭 IP
variable "aws_customer_gateway_ip" {
  description = "Customer Gateway IP from AWS side"
  type        = string
}

# 양쪽이 공유하는 VPN 터널 비밀키
variable "vpn_shared_secret" {
  description = "Shared secret used for VPN tunnel between AWS and GCP"
  type        = string
}

# GCP 서브넷 CIDR
variable "gcp_private_subnet_cidr" {
  description = "CIDR block of the GCP private subnet"
  type        = string
}

# AWS 서브넷 CIDR (라우팅용)
variable "aws_private_subnet_cidr" {
  description = "CIDR block of the AWS private subnet to route to"
  type        = string
}


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
