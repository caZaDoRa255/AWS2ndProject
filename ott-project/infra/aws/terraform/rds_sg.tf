resource "aws_security_group" "rds_mysql_sg" {
  name        = "rds-mysql-sg"
  description = "Allow MySQL access"
  vpc_id      = local.vpc_id

  ingress {
    description = "MySQL access from within VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # var.cidr 대신 하드코딩 (확실하게)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-mysql-sg"
    Environment = "Dev"
    Project     = "OTT"
  }
}
