variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address to access the bastion host"
  type        = string
}
