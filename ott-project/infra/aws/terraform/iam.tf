# EKS 클러스터 역할
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "eks.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# admin 유저에 AmazonEKSFullAccess 정책 제거, 대신 아래 3개 정책만 부여
resource "aws_iam_user_policy_attachment" "admin_eks_cluster" {
  user       = "admin"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_user_policy_attachment" "admin_eks_service" {
  user       = "admin"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
resource "aws_iam_user_policy_attachment" "admin_eks_vpc_resource" {
  user       = "admin"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
# 이미 AllowAssumeEKSAdminRole 정책이 있으면 import해서 사용하거나 이름을 바꿔야 함 (중복 생성 방지)
resource "aws_iam_user_policy_attachment" "admin_ec2_full" {
  user       = "admin"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "admin_iam_full" {
  user       = "admin"
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# EKS 워커 노드 역할
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy" "allow_assume_eks_admin" {
  name        = "AllowAssumeEKSAdminRole_v2"  # 이름 변경으로 중복 방지
  description = "Allow admin user to assume EKSAdminRole"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "arn:aws:iam::646322278152:role/EKSAdminRole"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "admin_assume_eks_admin" {
  user       = "admin"
  policy_arn = aws_iam_policy.allow_assume_eks_admin.arn
}

resource "aws_iam_role" "EKSAdminRole" {
  name = "EKSAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::646322278152:user/admin"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}