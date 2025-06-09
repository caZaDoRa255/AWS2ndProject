resource "aws_db_instance" "mysql" {
  identifier             = "mydb" # ✅ 이렇게 바꾸세요
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_mysql_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "my-db-subnet-group"
  subnet_ids = local.private_subnet_ids
  tags = {
    Name = "My DB Subnet Group"
  }
}
