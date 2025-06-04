resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access to Bastion Host"
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 예: "1.2.3.4/32"
  }

    ingress {
    description = "Allow HTTP (port 80) from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg"
    Environment = "Dev"
    Project     = "OTT"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0eb302fcc77c2f8bd" # Amazon Linux 2 (서울 리전)
  instance_type               = "t2.micro"
  subnet_id                   = local.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = "kyes-key" # 실제 EC2 키페어 이름으로 교체

  tags = {
    Name        = "bastion-host"
    Environment = "Dev"
    Project     = "OTT"
  }
}
