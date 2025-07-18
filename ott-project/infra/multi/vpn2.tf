
# GCP Provider
provider "google" {
  credentials = file("C:/Users/sol/.gcp/ott-project-462006-20d0a27f8660.json")
  project     = "ott-project-462006"
  region      = "us-central1"
  alias       = "gcp"
}


# AWS Provider
provider "aws" {
  region  = "ap-northeast-2"
  alias  = "aws"
  profile = "admin"
  
}

# VPC ID를 직접 지정 (여러 VPC가 있을 때)
data "aws_vpc" "ott_project" {
  provider = aws.aws
  id = "vpc-0107377b3c9ed5272"  # AWS Terraform에서 사용 중인 VPC ID
}


data "google_compute_network" "custom_vpc" {
  provider = google.gcp
  name    = "custom-vpc"
  project = var.project_id # 너의 GCP 프로젝트 ID로 바꿔
}

# 먼저 이거 만들어야 한다. 근데 안쓰임 ㅠㅠ
resource "google_compute_address" "vpn_ip_0" {
  provider = google.gcp
  name   = "vpn-ip-0"
  region = "us-central1"
}

resource "google_compute_address" "vpn_ip_1" {
  provider = google.gcp
  name   = "vpn-ip-1"
  region = "us-central1"
}




resource "google_compute_router" "router" {
  provider = google.gcp
  name    = "cloud-router"
  region  = "us-central1"
  network = data.google_compute_network.custom_vpc.id
  bgp {
    asn = 64514
  }
}

resource "google_compute_ha_vpn_gateway" "vpn_gateway" {
  provider = google.gcp
  name    = "ha-vpn-gateway"
  network = data.google_compute_network.custom_vpc.id
  region  = "us-central1"
}
##### aws 시작 ######

resource "aws_customer_gateway" "gcp_1" {
  provider = aws.aws
  bgp_asn    = 64514 # GCP 쪽 Cloud Router ASN
  ip_address = "34.128.34.28" # 강제 주입 ip
  type       = "ipsec.1"
  tags = {
    Name = "GCP-Customer-Gateway-1"
  }
}

resource "aws_customer_gateway" "gcp_2" {
  provider = aws.aws
  bgp_asn    = 64514 # GCP 쪽 Cloud Router ASN
  ip_address = "34.153.246.253" # 강제 주입 ip
  type       = "ipsec.1"
  tags = {
    Name = "GCP-Customer-Gateway-2"
  }
}

resource "aws_vpn_gateway" "vgw" {
  provider = aws.aws
  amazon_side_asn = 64512
  vpc_id          = data.aws_vpc.ott_project.id # 네 VPC 리소스에 맞게 수정
  tags = {
    Name = "GCP-VPN-Gateway"
  }
}


resource "aws_vpn_connection" "vpn_1" {
  provider = aws.aws
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr = "169.254.10.0/30"
  tunnel1_preshared_key = "sharedsecret1a"
  

  tunnel2_inside_cidr = "169.254.10.4/30"
  tunnel2_preshared_key = "sharedsecret1b"
  

  tags = {
    Name = "GCP-VPN-Connection-1"
  }
}


resource "aws_vpn_connection" "vpn_2" {
  provider = aws.aws
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_2.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr = "169.254.11.0/30"
  tunnel1_preshared_key = "sharedsecret2a"
  

  tunnel2_inside_cidr = "169.254.11.4/30"
  tunnel2_preshared_key = "sharedsecret2b"
  

  tags = {
    Name = "GCP-VPN-Connection-2"
  }
}

#### peer vpn gateway 만들기 gcp

resource "google_compute_external_vpn_gateway" "aws_gateway" {
  provider = google.gcp
  name             = "aws-external-gateway"
  redundancy_type  = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.vpn_1.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.vpn_1.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.vpn_2.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.vpn_2.tunnel2_address
  }
}



######################################################## 터널 만들기 gcp
resource "google_compute_vpn_tunnel" "tunnel1a" {
  provider                        = google.gcp
  name                            = "gcp-to-aws-tunnel-1a"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = "sharedsecret1a"
  router                          = google_compute_router.router.id
  ike_version                     = 2

  depends_on = [aws_vpn_connection.vpn_1]
}

resource "google_compute_vpn_tunnel" "tunnel1b" {
  provider                        = google.gcp
  name                            = "gcp-to-aws-tunnel-1b"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 1
  shared_secret                   = "sharedsecret1b"
  router                          = google_compute_router.router.id
  ike_version                     = 2

  depends_on = [aws_vpn_connection.vpn_1]
}

resource "google_compute_vpn_tunnel" "tunnel2a" {
  provider                        = google.gcp
  name                            = "gcp-to-aws-tunnel-2a"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 2
  shared_secret                   = "sharedsecret2a"
  router                          = google_compute_router.router.id
  ike_version                     = 2

  depends_on = [aws_vpn_connection.vpn_2]
}

resource "google_compute_vpn_tunnel" "tunnel2b" {
  provider                        = google.gcp
  name                            = "gcp-to-aws-tunnel-2b"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.vpn_gateway.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.id
  peer_external_gateway_interface = 3
  shared_secret                   = "sharedsecret2b"
  router                          = google_compute_router.router.id
  ike_version                     = 2

  depends_on = [aws_vpn_connection.vpn_2]
}


#################################################################################

## BGP 세션 설정


## Tunnel 1a
resource "google_compute_router_interface" "tunnel1a_interface" {
  provider = google.gcp
  name       = "interface-1a"
  router     = google_compute_router.router.name
  region     = "us-central1"
  ip_range   = "169.254.10.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1a.name
}

resource "google_compute_router_peer" "tunnel1a_peer" {
  provider = google.gcp
  name                      = "peer-1a"
  router                    = google_compute_router.router.name
  region                    = "us-central1"
  interface                 = google_compute_router_interface.tunnel1a_interface.name
  peer_ip_address           = "169.254.10.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
}

## Tunnel 1b
resource "google_compute_router_interface" "tunnel1b_interface" {
  provider = google.gcp
  name       = "interface-1b"
  router     = google_compute_router.router.name
  region     = "us-central1"
  ip_range   = "169.254.10.6/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1b.name
}

resource "google_compute_router_peer" "tunnel1b_peer" {
  provider = google.gcp
  name                      = "peer-1b"
  router                    = google_compute_router.router.name
  region                    = "us-central1"
  interface                 = google_compute_router_interface.tunnel1b_interface.name
  peer_ip_address           = "169.254.10.5"
  peer_asn                  = 64512
  advertised_route_priority = 100
}

## Tunnel 2a
resource "google_compute_router_interface" "tunnel2a_interface" {
  provider = google.gcp
  name       = "interface-2a"
  router     = google_compute_router.router.name
  region     = "us-central1"
  ip_range   = "169.254.11.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2a.name
}

resource "google_compute_router_peer" "tunnel2a_peer" {
  provider = google.gcp
  name                      = "peer-2a"
  router                    = google_compute_router.router.name
  region                    = "us-central1"
  interface                 = google_compute_router_interface.tunnel2a_interface.name
  peer_ip_address           = "169.254.11.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
}

## Tunnel 2b
resource "google_compute_router_interface" "tunnel2b_interface" {
  provider = google.gcp
  name       = "interface-2b"
  router     = google_compute_router.router.name
  region     = "us-central1"
  ip_range   = "169.254.11.6/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2b.name
}

resource "google_compute_router_peer" "tunnel2b_peer" {
  provider = google.gcp
  name                      = "peer-2b"
  router                    = google_compute_router.router.name
  region                    = "us-central1"
  interface                 = google_compute_router_interface.tunnel2b_interface.name
  peer_ip_address           = "169.254.11.5"
  peer_asn                  = 64512
  advertised_route_priority = 100
}

# private route table을 data source로 조회
# (아래에 추가)
data "aws_route_tables" "private" {
  provider = aws.aws
  vpc_id   = data.aws_vpc.ott_project.id
}

resource "aws_route" "to_gcp_vpn" {
  count                  = length(data.aws_route_tables.private.ids)
  route_table_id         = data.aws_route_tables.private.ids[count.index]
  destination_cidr_block = "10.10.2.0/24" # 또는 var.gcp_vpc_private_cidr_block
  gateway_id             = aws_vpn_gateway.vgw.id
  provider               = aws.aws
}