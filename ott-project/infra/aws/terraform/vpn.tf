resource "aws_customer_gateway" "gcp_cgw" {
  bgp_asn    = 65000
  ip_address = data.terraform_remote_state.gcp.outputs.gcp_vpn_ip
  type       = "ipsec.1"
  tags = {
    Name = "GCP-Customer-Gateway"
  }
}

data "terraform_remote_state" "gcp" {
  backend = "local"
  config = {
    path = local.gcp_state_path
  }
}


locals {
  gcp_state_path = var.environment == "local" ? "C:/Users/sol/AWS2ndProject/ott-project/infra/gcp/terraform/terraform.tfstate" : "../../gcp/terraform/terraform.tfstate"
}


#----------------------------------------------------
#AWS VPN Gateway 생성
#VPN Gateway를 VPC에 연결 (위 코드가 이미 연결 포함이야)

resource "aws_vpn_gateway" "vgw" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "Main-VPN-Gateway"
  }
}


#-------------------------------------------------------
#AWS VPN Connection (GCP와 연결하는 핵심)
resource "aws_vpn_connection" "gcp_vpn" {
  customer_gateway_id = aws_customer_gateway.gcp_cgw.id
  type                = "ipsec.1"
  vpn_gateway_id      = aws_vpn_gateway.vgw.id

  static_routes_only = true  # static vpn 사용 = true
  tags = {
    Name = "VPN-to-GCP"
  }
}


#-------------------------------------------------------
#aws_vpn_connection_route → VPN 연결용 리소스
resource "aws_vpn_connection_route" "gcp_subnet" {
  vpn_connection_id      = aws_vpn_connection.gcp_vpn.id
  destination_cidr_block = var.gcp_private_subnet_cidr
}
