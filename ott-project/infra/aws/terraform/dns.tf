# dns.tf
data "aws_route53_zone" "link" {
  zone_id = "Z0854242A863LNCHFSQJ"
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.link.zone_id
  name    = "frontend.moodlyharbor.link"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

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
