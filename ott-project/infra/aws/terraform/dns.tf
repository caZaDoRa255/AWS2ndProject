# dns.tf
data "aws_route53_zone" "link" {
  zone_id = "Z0854242A863LNCHFSQJ"
}

# 기존 frontend 레코드는 react_app로 대체됨

# AWS React 앱을 위한 A 레코드는 react-deployment.tf에서 자동으로 생성됨

resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.link.zone_id
  name    = "backend.moodlyharbor.link"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

# FastAPI용 Route53 레코드 추가
resource "aws_route53_record" "fastapi" {
  zone_id = data.aws_route53_zone.link.zone_id
  name    = "api.moodlyharbor.click"
  type    = "A"
  ttl     = "300"
  records = [var.gcp_fastapi_private_ip]  # GCP FastAPI LoadBalancer External IP
}
