# AWS 디렉토리의 VPC 출력 참조
output "vpc_id" {
  description = "VPC ID from AWS directory"
  value       = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs from AWS directory"
  value       = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}

output "vpc_cidr_block" {
  description = "VPC CIDR block from AWS directory"
  value       = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
}

# EKS 클러스터 출력
output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.ott_eks.name
}

output "eks_cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = aws_eks_cluster.ott_eks.endpoint
}

output "eks_cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.ott_eks.arn
}

output "node_group_name" {
  description = "EKS 노드 그룹 이름"
  value       = aws_eks_node_group.ott_node_group.node_group_name
}

output "node_group_arn" {
  description = "EKS 노드 그룹 ARN"
  value       = aws_eks_node_group.ott_node_group.arn
} 