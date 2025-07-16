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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.4.0"
}

# AWS Provider
provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin"
}

# IAM for Fluent-bit
resource "aws_iam_role" "fluentbit_role" {
  name = "fluentbit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.ott_eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:fluent-bit"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fluentbit_policy" {
  name        = "fluentbit-policy"
  description = "Policy for Fluent Bit to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentbit_attach" {
  role       = aws_iam_role.fluentbit_role.name
  policy_arn = aws_iam_policy.fluentbit_policy.arn
}

# Data sources
data "aws_eks_cluster" "ott_eks" {
  name = "ott-eks"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Kubernetes provider for EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.ott_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.ott_eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.ott_eks.name]
  }
}

# Create namespace first
resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

# Fluent-bit deployment (Helm 대신 Kubernetes deployment 사용)
resource "kubernetes_deployment" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          app = "fluent-bit"
        }
      }

      spec {
        service_account_name = "fluent-bit"
        container {
          name  = "fluent-bit"
          image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
          
          env {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
          }
          
          env {
            name  = "CLOUDWATCH_LOG_GROUP"
            value = "/aws/eks/${data.aws_eks_cluster.ott_eks.name}/logs"
          }
          
          env {
            name  = "CLOUDWATCH_LOG_STREAM_PREFIX"
            value = "fluent-bit-"
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
}

resource "kubernetes_service_account" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluentbit_role.arn
    }
  }
  
  depends_on = [kubernetes_namespace.amazon_cloudwatch]
}
