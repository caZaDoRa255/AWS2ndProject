# acm.tf
resource "aws_acm_certificate" "eks" {
  domain_name               = "moodlyharbor.click"
  subject_alternative_names = [
    "moodlyharbor.click",
    "moodlyharbor.link",
    "frontend.moodlyharbor.link",
    "backend.moodlyharbor.link"
  ]
  validation_method = "DNS"
  
}


# .click 도메인 DNS 검증용
resource "aws_route53_record" "cert_validation_click" {
  for_each = {
    for dvo in aws_acm_certificate.eks.domain_validation_options :
    dvo.domain_name => dvo if endswith(dvo.domain_name, "moodlyharbor.click")
  }

  zone_id = data.aws_route53_zone.click.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300
  records = [each.value.resource_record_value]
}

# .link 도메인 DNS 검증용
resource "aws_route53_record" "cert_validation_link" {
  for_each = {
    for dvo in aws_acm_certificate.eks.domain_validation_options :
    dvo.domain_name => dvo if endswith(dvo.domain_name, "moodlyharbor.link")
  }

  zone_id = data.aws_route53_zone.link.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300
  records = [each.value.resource_record_value]
}

resource "aws_acm_certificate_validation" "eks" {
  certificate_arn = aws_acm_certificate.eks.arn
  validation_record_fqdns = concat(
    [for record in aws_route53_record.cert_validation_click : record.fqdn],
    [for record in aws_route53_record.cert_validation_link  : record.fqdn]
  )
}


