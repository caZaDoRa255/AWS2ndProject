terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS 디렉토리의 VPC 모듈 참조
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../aws/terraform/terraform.tfstate"
  }
}

# EKS 클러스터와 관련 리소스들은 eks.tf, eks_iam.tf, irsa.tf에 정의됨 