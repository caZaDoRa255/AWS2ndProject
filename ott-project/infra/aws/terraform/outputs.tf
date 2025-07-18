# EKS 관련 출력은 infra/eks/outputs.tf에서 관리됨

# output "eks_cluster_name" {
#   value = aws_eks_cluster.ott_eks.name
# }

# output "node_group_name" {
#   value = aws_eks_node_group.ott_node_group.node_group_name
# }

# output "rds_sg_id" {
#   description = "ID of RDS MySQL Security Group"
#   value       = aws_security_group.rds_mysql_sg.id
# }

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
  description = "The public IP address of the bastion host"
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "alb_dns_name" {
  value = aws_lb.harbor_alb.dns_name
  description = "The DNS name of the ALB"
}

output "alb_zone_id" {
  value = aws_lb.harbor_alb.zone_id
  description = "The Route 53 zone ID of the ALB"
}

# React 앱 관련 출력
output "react_alb_dns_name" {
  description = "React 앱 ALB DNS 이름"
  value       = aws_lb.web.dns_name
}

output "react_app_url" {
  description = "React 앱 접속 URL"
  value       = "https://frontend.moodlyharbor.link"
}

output "fastapi_backend_private_ip" {
  description = "The private IP address of the FastAPI backend VM."
  value       = var.gcp_fastapi_private_ip
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}