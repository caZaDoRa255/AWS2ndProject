module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2" # 안정 버전 사용

  name = "ott-project-vpc"
  cidr = "10.0.0.0/16"
  

  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project     = "OTT"
    Environment = "Dev"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"        = "1"
    "kubernetes.io/cluster/ott-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/ott-eks"   = "shared"
  }
}

# data "aws_route_tables" "private" {
#   vpc_id = module.vpc.vpc_id
# }

# NAT Gateway 라우트 - 조건부 생성
# resource "aws_route" "force_nat_gateway" {
#   count = length(data.aws_route_tables.private.ids)
  
#   route_table_id         = data.aws_route_tables.private.ids[count.index]
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = module.vpc.natgw_ids[0]
  
#   depends_on = [module.vpc]
  
#   # 라우트가 이미 존재하면 무시
#   lifecycle {
#     ignore_changes = [route_table_id, destination_cidr_block]
#   }
# }

#------------------------------------------------------
#aws_route → VPC 라우팅 테이블 설정 (vpn2.tf에서 처리하므로 주석 처리)
# resource "aws_route" "to_gcp" {
#   route_table_id         = module.vpc.private_route_table_ids[0] 
#   destination_cidr_block = var.gcp_private_subnet_cidr
#   gateway_id             = aws_vpn_gateway.vgw.id
# }

# GCP VPC로 가는 라우트 추가 (VPN Gateway)
# aws_vpn_gateway.vgw.id는 infra/multi/vpn2.tf에서 선언되어 있으므로, 실제 적용 시 output/input 구조로 받아와야 함
# 아래 코드는 infra/aws/terraform에서 VPN Gateway를 직접 관리할 때만 정상 동작
# resource "aws_route" "to_gcp_vpn" {
#   count                  = length(module.vpc.private_route_table_ids)
#   route_table_id         = module.vpc.private_route_table_ids[count.index]
#   destination_cidr_block = var.gcp_vpc_private_cidr_block
#   gateway_id             = aws_vpn_gateway.vgw.id
# }

# ECR VPC 엔드포인트 (EKS 노드가 ECR에서 이미지를 가져오기 위해 필요)
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
#   private_dns_enabled = true

#   tags = {
#     Name    = "ecr-api-endpoint"
#     Project = "OTT"
#   }
# }

# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
#   private_dns_enabled = true

#   tags = {
#     Name    = "ecr-dkr-endpoint"
#     Project = "OTT"
#   }
# }

# VPC 엔드포인트용 보안 그룹
resource "aws_security_group" "vpc_endpoints_sg" {
  name_prefix = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  # HTTPS 트래픽 허용 (VPC 엔드포인트는 HTTPS만 사용)
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "vpc-endpoints-sg"
    Project = "OTT"
  }
}
