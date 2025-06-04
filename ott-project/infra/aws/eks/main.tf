terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name            = "eks-vpc"
  cidr            = "172.28.0.0/16"
  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets = ["172.28.11.0/24", "172.28.31.0/24"]
  public_subnets  = ["172.28.10.0/24", "172.28.30.0/24"]

  # Kubernetes에서 AWS ELB를 사용하여 서비스의 로드밸런싱 자동화 설정
  public_subnet_tags = {
    # 인터넷에 노출된 ELB
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    # VPC 내에서만 접근 가능한 ELB
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  # EKS Cluster Setting
  cluster_name    = "my-eks"
  cluster_version = "1.32"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # EKS Worker Node 정의 ( ManagedNode방식: Launch Template 자동 구성 )
  eks_managed_node_groups = {
    initial = {
      instance_types         = ["t3.small"]
      min_size               = 2
      max_size               = 3
      desired_size           = 2
      vpc_security_group_ids = [module.add_node_sg.security_group_id]
      credit_specification = {
        cpu_credits = "standard" # 성능제한, 요금 발생x
        #  cpu_credits = unlimited(초과 시 요금 발생) --> 설정하면 요금 폭탄
      }
    }
  }

  # public-subnet(bastion)과 API와 통신하기 위해 설정(443)
  cluster_additional_security_group_ids = [module.add_cluster_sg.security_group_id]
  cluster_endpoint_public_access        = true

  # AWS EKS 클러스터를 생성할 때, 
  # 해당 클러스터를 생성한 IAM 사용자에게 관리자 권한을 부여하는 옵션
  # K8s ConfigMap Object "aws_auth" 구성
  # 구성 후 명령어로 확인 가능, kubectl -n kube-system get configmap aws-auth -o yaml
  enable_cluster_creator_admin_permissions = true
}

module "bastion_host" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  depends_on                  = [module.eks]
  ami                         = "ami-0eb302fcc77c2f8bd" # AL2023
  name                        = "bastion-host"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "kyes-key"
  monitoring                  = true
  vpc_security_group_ids      = [module.bastion_host_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  user_data = templatefile("${path.module}/userdata.sh.tpl",
    {
      ACCESS_KEY = var.access_key
      SECRET_KEY = var.secret_key
    }
  )
}

module "nat_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  ami                         = "ami-01ad0c7a4930f0e43"
  name                        = "nat-instance"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = "kyes-key"
  source_dest_check           = false
  vpc_security_group_ids      = [module.nat_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[1]
}

# Private Subnet Routing Table ( dest: NAT Instance ENI )
resource "aws_route" "private_subnet" {
  count                  = 2
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat_instance.primary_network_interface_id
}
#라우트 하나 더 추가하기.
output "bastion_ip" {
  value       = module.bastion_host.public_ip
  description = "bastion-host public IP"
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

/*
C:\terraform\workspace> cd .\00_eks\
C:\terraform\workspace\00_eks> terraform fmt
C:\terraform\workspace\00_eks> terraform init 
C:\terraform\workspace\00_eks> terraform apply
C:\terraform\workspace\00_eks> terraform destroy
*/

#------------------------------------------- 매우 중요!#

resource "null_resource" "install_harbor" {
  depends_on = [module.bastion_host]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = module.bastion_host.public_ip
      private_key = file("~/.ssh/kyes-key.pem")
    }

    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y docker",
      "sudo dnf install -y libxcrypt-compat || true",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      

      "cd /opt",
      "sudo wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz",
      "sudo tar xvf harbor-online-installer-v2.10.0.tgz",
      "cd harbor",

      "sudo cp harbor.yml.tmpl harbor.yml",
      "sudo sed -i \"s/^hostname: .*/hostname: ${module.bastion_host.public_ip}/\" harbor.yml",
      "sudo sed -i 's/^  port: 443/#  port: 443/' harbor.yml",
      "sudo sed -i 's/^https:/#https:/' harbor.yml",
      "sudo sed -i 's/^  certificate/#  certificate/' harbor.yml",
      "sudo sed -i 's/^  private_key/#  private_key/' harbor.yml",

      "sudo ./install.sh"
    ]
  }
}

data "aws_route53_zone" "main" {
  name = "moodlyharbor.click"  # 너의 도메인
}

resource "aws_route53_record" "bastion_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.moodlyharbor.click"   # 서브도메인
  type    = "A"
  ttl     = 300
  records = [module.bastion_host.public_ip]
}