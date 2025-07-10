# AWS VPN Gateway + GCP Cloud VPN 설정
# 주의: vpn2.tf에서 HA VPN을 사용하므로 이 설정은 주석 처리

# GCP VPN Gateway IP를 위한 변수 추가
# variable "gcp_vpn_gateway_ip" {
#   description = "GCP VPN Gateway의 외부 IP 주소"
#   type        = string
#   default     = ""  # GCP에서 생성된 후 입력
# }

# variable "vpn_shared_secret" {
#   description = "VPN 터널 공유 비밀키"
#   type        = string
#   sensitive   = true
#   default     = "your-vpn-shared-secret-here"
# }

# variable "gcp_private_subnet_cidr" {
#   description = "GCP 프라이빗 서브넷 CIDR"
#   type        = string
#   default     = "10.128.0.0/20"
# }

# AWS Customer Gateway (GCP VPN Gateway에 연결)
# resource "aws_customer_gateway" "gcp_cgw" {
#   bgp_asn    = 65000
#   ip_address = var.gcp_vpn_gateway_ip
#   type       = "ipsec.1"
#   tags = {
#     Name = "GCP-Customer-Gateway"
#   }
# }

# AWS VPN Gateway
# resource "aws_vpn_gateway" "vgw" {
#   vpc_id = module.vpc.vpc_id
#   tags = {
#     Name = "Main-VPN-Gateway"
#   }
# }

# AWS VPN Connection (GCP와 연결)
# resource "aws_vpn_connection" "gcp_vpn" {
#   customer_gateway_id = aws_customer_gateway.gcp_cgw.id
#   type                = "ipsec.1"
#   vpn_gateway_id      = aws_vpn_gateway.vgw.id
#   static_routes_only  = true

#   tags = {
#     Name = "VPN-to-GCP"
#   }
# }

# AWS에서 GCP로 가는 라우트
# resource "aws_vpn_connection_route" "gcp_subnet" {
#   vpn_connection_id      = aws_vpn_connection.gcp_vpn.id
#   destination_cidr_block = var.gcp_private_subnet_cidr
# }

# AWS VPC 라우팅 테이블에 GCP로 가는 라우트 추가
# resource "aws_route" "vpc_to_gcp" {
#   route_table_id         = module.vpc.private_route_table_ids[0]
#   destination_cidr_block = var.gcp_private_subnet_cidr
#   gateway_id             = aws_vpn_gateway.vgw.id
# }

# VPN 연결 상태 확인을 위한 출력
# output "aws_vpn_connection_id" {
#   description = "AWS VPN Connection ID"
#   value       = aws_vpn_connection.gcp_vpn.id
# }

# output "aws_customer_gateway_ip" {
#   description = "AWS Customer Gateway IP (GCP에서 사용)"
#   value       = aws_customer_gateway.gcp_cgw.ip_address
# }


