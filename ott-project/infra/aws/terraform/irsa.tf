# 1. IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${aws_eks_cluster.ott_cluster.name}"
  description = "IAM policy for AWS Load Balancer Controller to manage ALBs"
  policy      = file("iam_policy.json")
}

# 2. IAM Role for Service Account (IRSA)
resource "aws_iam_role" "alb_controller_irsa_role" {
  name = "AmazonEKS_AWSLoadBalancerControllerRole-${aws_eks_cluster.ott_cluster.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.ott_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.ott_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
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
