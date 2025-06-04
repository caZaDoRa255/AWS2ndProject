output "eks_cluster_name" {
  value = aws_eks_cluster.ott_cluster.name
}

output "node_group_name" {
  value = aws_eks_node_group.ott_node_group.node_group_name
}

output "rds_sg_id" {
  description = "ID of RDS MySQL Security Group"
  value       = aws_security_group.rds_mysql_sg.id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}
