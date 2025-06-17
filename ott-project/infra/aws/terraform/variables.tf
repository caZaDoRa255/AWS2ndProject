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
