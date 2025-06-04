# 루트 레벨에 있는 variables.tf

variable "db_password" {
  description = "Password for RDS database"
  type        = string
  sensitive   = true
}
