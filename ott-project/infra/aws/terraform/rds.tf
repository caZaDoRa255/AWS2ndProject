# resource "aws_db_instance" "mydb" {
#   identifier             = "mydb" # ✅ 이렇게 바꾸세요
#   allocated_storage      = 20
#   engine                 = "mysql"
#   engine_version         = "8.0"
#   instance_class         = "db.t3.micro"
#   username               = "admin"
#   password               = var.db_password
#   parameter_group_name   = "default.mysql8.0"
#   skip_final_snapshot    = true
#   publicly_accessible = true
#   vpc_security_group_ids = [aws_security_group.rds_mysql_sg.id]
#   db_subnet_group_name   = aws_db_subnet_group.default.name
# }

# resource "aws_db_subnet_group" "default" {
#   name       = "my-db-subnet-group"
#   subnet_ids = module.vpc.public_subnets
#   tags = {
#     Name = "My DB Subnet Group"
#   }
# }
