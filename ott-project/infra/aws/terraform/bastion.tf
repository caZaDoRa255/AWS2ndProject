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
  
  ingress {
    description = "Allow HTTPS (port 443) from anywhere"
    from_port   = 443
    to_port     = 443
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
  ami                         = "ami-0e967ff96936c0c0c" # Amazon Linux 2.23 (서울 리전)
  instance_type               = "t2.micro"
  subnet_id                   = local.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name # 이 줄 추가
  key_name                    = "kyes-key" # 실제 EC2 키페어 이름으로 교체

  metadata_options {
    http_tokens = "optional"
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl",
    {
      ACCESS_KEY = var.access_key
      SECRET_KEY = var.secret_key
      CLUSTER_NAME = var.eks_cluster_name
      ACCOUNT_ID     = data.aws_caller_identity.current.account_id
      ROLE_NAME = var.role_name
      AWS_REGION = var.aws_region
      PROFILE_NAME  = var.profile_name
    }
  )

  tags = {
    Name        = "bastion-host"
    Environment = "Dev"
    Project     = "OTT"
  }
}
