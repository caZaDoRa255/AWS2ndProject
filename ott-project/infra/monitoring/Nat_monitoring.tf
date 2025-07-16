# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/aws/vpc-flow-logs/ott-project"
  retention_in_days = 7
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_policy" "vpc_flow_log_policy" {
  name   = "vpc-flow-log-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "vpc_flow_log_attachment" {
  role       = aws_iam_role.vpc_flow_log_role.name
  policy_arn = aws_iam_policy.vpc_flow_log_policy.arn
}

# Data source for VPC
data "aws_vpc" "ott_vpc" {
  tags = {
    Name = "ott-project-vpc"
  }
}

# VPC Flow Log Resource
resource "aws_flow_log" "ott_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = data.aws_vpc.ott_vpc.id

  depends_on = [aws_iam_role_policy_attachment.vpc_flow_log_attachment]
}
