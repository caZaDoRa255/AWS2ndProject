# irsa.tf (수정 후)

# EKS Cluster Data Source (기존 EKS Cluster 정보를 가져오기 위함)
data "aws_eks_cluster" "ott_eks" {
  name = var.eks_cluster_name # 이미 수정하셨을 것으로 보입니다.
}


# 1. IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.eks_cluster_name}" # <-- 여기를 var.eks_cluster_name으로 변경
  description = "IAM policy for AWS Load Balancer Controller to manage ALBs"
  policy      = file("iam_policy.json")
}

# 2. IAM Role for Service Account (IRSA)
resource "aws_iam_role" "alb_controller_irsa_role" {
  name               = "AmazonEKS_AWSLoadBalancerControllerRole-${var.eks_cluster_name}" # <-- 여기를 var.eks_cluster_name으로 변경
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# 3. IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa_role.name
}


