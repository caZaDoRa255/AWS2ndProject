variable "access_key" {
  description = "AWS access key for user_data"
  type        = string
}

variable "secret_key" {
  description = "AWS secret key for user_data"
  type        = string
}

variable "role_name" {
  description = "IAM Role name for ALB Controller"
  type        = string
}

variable "region" {
  description = "AWS region for EKS and ALB (used in templatefile)"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_region" {
  description = "AWS region (used in provider)"
  type        = string
  default     = "ap-northeast-2"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ott-eks"
}

variable "profile_name" {
  description = "AWS CLI profile name"
  type        = string
  default     = "admin"
}

variable "key_pair_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address to access the bastion host"
  type        = string
}

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "environment" {
  description = "Execution environment (local or shared)"
  type        = string
  default     = "local"
}

# variable "gcp_private_subnet_cidr" {
#   description = "GCP VPC의 프라이빗 서브넷 CIDR 블록"
#   type        = string
# }

variable "iam_user_arn" {
  type        = string
  description = "ARN of the IAM user or role to grant access to the S3 bucket"
}

# GCP VPC 네트워크의 프라이빗 CIDR 블록 변수
variable "gcp_vpc_private_cidr_block" {
  description = "The private CIDR block of your GCP VPC where the VM is located. (e.g., '10.128.0.0/20')"
  type        = string
}

variable "fastapi_secret_key" {
  description = "Secret key for FastAPI backend and Lambda callback."
  type        = string
  sensitive   = true # 이 변수는 민감한 정보임을 표시 (출력 시 숨김)
}

variable "gcp_fastapi_private_ip" {
  description = "GCP FastAPI VM의 프라이빗 IP 주소"
  type        = string
}

