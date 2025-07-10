# GCP Cloud VPN + AWS VPN Gateway 설정
# 주의: vpn2.tf에서 HA VPN을 사용하므로 이 설정은 주석 처리

# AWS Customer Gateway IP를 위한 변수 추가
# variable "aws_customer_gateway_ip" {
#   description = "AWS Customer Gateway의 외부 IP 주소"
#   type        = string
#   default     = ""  # AWS에서 생성된 후 입력
# }

# variable "aws_private_subnet_cidr" {
#   description = "AWS 프라이빗 서브넷 CIDR"
#   type        = string
#   default     = "10.0.0.0/16"
# }

# GCP VPN Gateway용 정적 IP
# resource "google_compute_address" "vpn_static_ip" {
#   name         = "gcp-vpn-static-ip"
#   address_type = "EXTERNAL"
#   region       = var.gcp_region
# }

# GCP VPN Gateway
# resource "google_compute_vpn_gateway" "aws_vpn_gateway" {
#   name    = "aws-vpn-gateway"
#   network = google_compute_network.vpc_network.self_link
#   region  = var.gcp_region
# }

# ESP 포트 포워딩
# resource "google_compute_forwarding_rule" "esp_forwarding_rule" {
#   name        = "esp-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "ESP"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# UDP 500 포트 (IKE)
# resource "google_compute_forwarding_rule" "udp500_forwarding_rule" {
#   name        = "udp500-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "UDP"
#   port_range  = "500"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# UDP 4500 포트 (NAT-T)
# resource "google_compute_forwarding_rule" "udp4500_forwarding_rule" {
#   name        = "udp4500-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "UDP"
#   port_range  = "4500"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# GCP VPN 터널 (AWS와 연결)
# resource "google_compute_vpn_tunnel" "aws_tunnel" {
#   name                 = "aws-tunnel"
#   region               = var.gcp_region
#   target_vpn_gateway   = google_compute_vpn_gateway.aws_vpn_gateway.self_link
#   peer_ip              = var.aws_customer_gateway_ip
#   shared_secret        = var.vpn_shared_secret
#   ike_version          = 2

#   local_traffic_selector  = [var.gcp_private_subnet_cidr]
#   remote_traffic_selector = [var.aws_private_subnet_cidr]

#   depends_on = [
#     google_compute_forwarding_rule.esp_forwarding_rule,
#     google_compute_forwarding_rule.udp500_forwarding_rule,
#     google_compute_forwarding_rule.udp4500_forwarding_rule
#   ]
# }

# GCP에서 AWS로 가는 라우트
# resource "google_compute_route" "to_aws" {
#   name                   = "route-to-aws"
#   network                = google_compute_network.vpc_network.name
#   dest_range             = var.aws_private_subnet_cidr
#   priority               = 1000
#   next_hop_vpn_tunnel    = google_compute_vpn_tunnel.aws_tunnel.self_link
# }

# VPN 연결 상태 확인을 위한 출력
# output "gcp_vpn_gateway_ip" {
#   description = "GCP VPN Gateway IP (AWS에서 사용)"
#   value       = google_compute_address.vpn_static_ip.address
# }

# output "gcp_vpn_tunnel_status" {
#   description = "GCP VPN 터널 상태"
#   value       = google_compute_vpn_tunnel.aws_tunnel.status
# }



