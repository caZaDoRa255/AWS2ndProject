# resource "google_compute_address" "vpn_static_ip" {
#   name         = "gcp-vpn-static-ip"
#   address_type = "EXTERNAL"
#   region       = var.gcp_region
# }

# resource "google_compute_vpn_gateway" "aws_vpn_gateway" {
#   name    = "aws-vpn-gateway"
#   network = google_compute_network.vpc_network.self_link
#   region  = var.gcp_region
# }

# # 📌 ESP 포트 포워딩
# resource "google_compute_forwarding_rule" "esp_forwarding_rule" {
#   name        = "esp-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "ESP"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# # 📌 UDP 500 포트 (IKE)
# resource "google_compute_forwarding_rule" "udp500_forwarding_rule" {
#   name        = "udp500-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "UDP"
#   port_range  = "500"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# # 📌 UDP 4500 포트 (NAT-T)
# resource "google_compute_forwarding_rule" "udp4500_forwarding_rule" {
#   name        = "udp4500-forwarding-rule"
#   region      = var.gcp_region
#   ip_protocol = "UDP"
#   port_range  = "4500"
#   ip_address  = google_compute_address.vpn_static_ip.address
#   target      = google_compute_vpn_gateway.aws_vpn_gateway.id
# }

# # 📌 GCP 라우팅: AWS로 트래픽 보내기
# resource "google_compute_vpn_tunnel" "aws_tunnel" {
#   name                 = "aws-tunnel"
#   region               = var.gcp_region
#   target_vpn_gateway   = google_compute_vpn_gateway.aws_vpn_gateway.self_link
#   peer_ip              = var.aws_customer_gateway_ip  # AWS에서 만들어진 Customer Gateway IP
#   shared_secret        = var.vpn_shared_secret        # AWS쪽 터널과 동일한 비밀키
#   ike_version          = 2

#   local_traffic_selector  = [var.gcp_private_subnet_cidr]
#   remote_traffic_selector = [var.aws_private_subnet_cidr]

#   depends_on = [
#     google_compute_forwarding_rule.esp_forwarding_rule,
#     google_compute_forwarding_rule.udp500_forwarding_rule,
#     google_compute_forwarding_rule.udp4500_forwarding_rule
#   ]
# }

# resource "google_compute_route" "to_aws" {
#   name                   = "route-to-aws"
#   network                = google_compute_network.vpc_network.name
#   dest_range             = var.aws_private_subnet_cidr
#   priority               = 1000
#   next_hop_vpn_tunnel    = google_compute_vpn_tunnel.aws_tunnel.self_link
# }

