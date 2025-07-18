# AWS 디렉토리의 VPC 모듈 사용
locals {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}

# 기존 Bastion 보안 그룹 데이터 소스
data "aws_security_group" "bastion" {
  name = "bastion-sg"
}

resource "aws_eks_cluster" "ott_eks" {
  name     = "ott-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = local.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# 기존 SSH 키 페어 사용
data "aws_key_pair" "eks_key" {
  key_name = "team4-key"
}

# EKS 노드용 보안 그룹 - 기본 설정
resource "aws_security_group" "eks_nodes_sg" {
  name_prefix = "eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = local.vpc_id

  # 노드 간 통신 허용
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "eks-nodes-sg"
    Project = "OTT"
  }
}

# VPC 엔드포인트용 보안 그룹
resource "aws_security_group" "vpc_endpoints_sg" {
  name_prefix = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  # HTTPS 트래픽 허용 (VPC 엔드포인트는 HTTPS만 사용)
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
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

# ECR API VPC 엔드포인트
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name    = "ecr-api-endpoint"
    Project = "OTT"
  }
}

# ECR DKR VPC 엔드포인트
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name    = "ecr-dkr-endpoint"
    Project = "OTT"
  }
}

# EKS API VPC 엔드포인트
resource "aws_vpc_endpoint" "eks_api" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name    = "eks-api-endpoint"
    Project = "OTT"
  }
}

# S3 VPC 엔드포인트 (ECR 이미지 레이어 다운로드용)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.terraform_remote_state.vpc.outputs.private_route_table_ids

  tags = {
    Name    = "s3-endpoint"
    Project = "OTT"
  }
}

# EKS 노드 그룹 - 기본 설정
resource "aws_eks_node_group" "ott_node_group" {
  cluster_name    = aws_eks_cluster.ott_eks.name
  node_group_name = "ott-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  tags = {
    Name    = "ott-node-group"
    Project = "OTT"
  }

  depends_on = [
    aws_eks_cluster.ott_eks,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.eks_api,
    aws_vpc_endpoint.s3
  ]
}

