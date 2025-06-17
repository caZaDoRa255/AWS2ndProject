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
