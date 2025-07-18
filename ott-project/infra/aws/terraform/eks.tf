# EKS 관련 리소스는 infra/eks 디렉토리로 분리됨
# 아래 리소스들은 infra/eks/eks.tf에서 관리됨

# resource "aws_eks_cluster" "ott_eks" {
#   name     = "ott-eks"
#   role_arn = aws_iam_role.eks_cluster_role.arn

#   vpc_config {
#     subnet_ids = module.vpc.private_subnets
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
#   ]
# }

# # EKS 노드 그룹 - 기본 설정
# resource "aws_eks_node_group" "ott_node_group" {
#   cluster_name    = aws_eks_cluster.ott_eks.name
#   node_group_name = "ott-node-group-v6"
#   node_role_arn   = aws_iam_role.eks_node_role.arn
#   subnet_ids      = module.vpc.private_subnets

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   instance_types = ["t3.medium"]

#   tags = {
#     Name    = "ott-node-group-v6"
#     Project = "OTT"
#   }

#   depends_on = [
#     aws_eks_cluster.ott_eks
#   ]
# }

# # EKS 노드용 보안 그룹
# resource "aws_security_group" "eks_nodes_sg" {
#   name_prefix = "eks-nodes-sg"
#   description = "Security group for EKS nodes"
#   vpc_id      = module.vpc.vpc_id

#   # SSH 접근 허용 (Bastion 호스트에서만)
#   ingress {
#     description     = "SSH from bastion"
#     from_port       = 22
#     to_port         = 22
#     protocol        = "tcp"
#     security_groups = [aws_security_group.bastion_sg.id]
#   }

#   # 노드 간 통신 허용
#   ingress {
#     description = "Node to node communication"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#   }

#   # 모든 아웃바운드 트래픽 허용
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name    = "eks-nodes-sg"
#     Project = "OTT"
#   }
# }

