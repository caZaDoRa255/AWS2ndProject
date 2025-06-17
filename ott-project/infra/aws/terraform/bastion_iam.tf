resource "aws_iam_role" "bastion_role" {
  name = "BastionHostRole-ott-eks"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "BastionHostRole-ott-eks"
    Environment = "dev"
  }
}



resource "aws_iam_role_policy_attachment" "bastion_ssm_policy_attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "BastionHostInstanceProfile-ott-eks"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_policy" "eks_describe_cluster_policy" {
  name        = "BastionEKSDescribeClusterPolicy-ott-eks"
  description = "Policy to allow Bastion Host to describe EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
            {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "ssm:GetParameter" # kubectl-aws-iam-authenticator (eks get-token) 가 SSM 파라미터를 읽을 때 필요
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/aws/service/eks/optimized-ami/*/amazon-linux-2/recommended/release-version"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_eks_policy_attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.eks_describe_cluster_policy.arn
}