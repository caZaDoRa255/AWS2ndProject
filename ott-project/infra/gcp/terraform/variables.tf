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
  default = "10.0.1.0/24"
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
  default = "10.0.2.0/24"
}

variable "private_vm_name" {
  type    = string
  default = "private-vm"
}

variable "gke_cluster_name" {
  default = "demo-gke"
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

