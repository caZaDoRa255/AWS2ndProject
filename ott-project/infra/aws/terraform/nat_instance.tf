resource "aws_security_group" "nat_sg" {
  name        = "nat-sg"
  description = "Allow NAT traffic"
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow traffic from private subnet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "nat-sg"
    Environment = "Dev"
    Project     = "OTT"
  }
}

resource "aws_instance" "nat" {
  ami                         = "ami-0c9c942bd7bf113a2" # Amazon Linux 2 (NAT용 AMI로 교체 가능)
  instance_type               = "t2.micro"
  subnet_id                   = local.public_subnet_ids[1]
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false # NAT 필수 설정

  tags = {
    Name        = "nat-instance"
    Environment = "Dev"
    Project     = "OTT"
  }
}
