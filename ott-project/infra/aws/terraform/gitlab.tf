module "private_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.0"

  name = "gitlab-runner"

  ami           = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"

  subnet_id = module.vpc.private_subnets[0]

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  associate_public_ip_address = false
  key_name = "team4-key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install epel -y
              yum install -y curl

              # GitLab Runner 설치
              curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
              yum install -y gitlab-runner

              systemctl enable gitlab-runner
              systemctl start gitlab-runner

              # GitLab Runner 등록 (token 등 수동 입력 필요)
              echo 'Runner 설치 완료. 수동으로 다음 명령을 실행하세요:'
              echo 'sudo gitlab-runner register'
              EOF

  tags = {
    Name        = "gitlab-runner"
    Environment = "Dev"
  }
}




resource "aws_security_group" "private_sg" {
  name        = "private-ec2-sg"
  description = "Allow SSH from bastion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}