output "eks_cluster_name" {
  value = aws_eks_cluster.ott_eks.name
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
