terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin"
}

data "aws_caller_identity" "current" {}

# EKS 클러스터 데이터 소스
data "aws_eks_cluster" "ott_eks" {
  name = "ott-eks"
}

data "aws_eks_cluster_auth" "ott_eks" {
  name = "ott-eks"
}

# Kubernetes Provider 설정
provider "kubernetes" {
  host                   = data.aws_eks_cluster.ott_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.ott_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.ott_eks.token
}

locals {
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets
  public_subnet_ids   = module.vpc.public_subnets
}


