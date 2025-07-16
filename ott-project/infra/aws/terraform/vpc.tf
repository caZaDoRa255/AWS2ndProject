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

data "aws_route_tables" "private" {
  vpc_id = module.vpc.vpc_id
}

# NAT Gateway 라우트가 이미 존재하는지 확인하고 없을 때만 생성
resource "aws_route" "force_nat_gateway" {
  count                  = length(data.aws_route_tables.private.ids)
  route_table_id         = data.aws_route_tables.private.ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc.natgw_ids[0]
  depends_on             = [module.vpc]
  
  # 라우트가 이미 존재하면 오류를 무시
  lifecycle {
    ignore_changes = [route_table_id]
  }
}

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
