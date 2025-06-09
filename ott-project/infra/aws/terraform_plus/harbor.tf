# Harbor 설치 리소스 정의

resource "null_resource" "install_harbor" {
  depends_on = [aws_instance.bastion]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.bastion.public_ip
      private_key = file("~/.ssh/kyes-key.pem")# 실제 사용중인 키 경로로 변경
    }

    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y docker",
      "sudo dnf install -y libxcrypt-compat || true",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Docker Compose 설치
      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      # Harbor 다운로드 및 압축 해제
      "cd /opt",
      "sudo wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz",
      "sudo tar xvf harbor-online-installer-v2.10.0.tgz",
      "cd harbor",

      # harbor.yml 설정
      "sudo cp harbor.yml.tmpl harbor.yml",
      "sudo sed -i \"s/^hostname: .*/hostname: www.moodlyharbor.click/\" harbor.yml",
      "echo 'external_url: https://www.moodlyharbor.click' | sudo tee -a harbor.yml",
      "sudo sed -i '/^https:/,/^  private_key:/ s/^/#/' harbor.yml",
      "sudo sed -i '/^http:/,/^  port:/ s/^#//' harbor.yml",
      "sudo sed -i '/^  port:/ s/.*/  port: 80/' harbor.yml",

      # Harbor 설치
      "sudo ./install.sh"
      ]
  }
}

# Route53 도메인

data "aws_route53_zone" "main" {
  name = "moodlyharbor.click"
}

# resource "aws_route53_record" "bastion_record" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.moodlyharbor.click"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.bastion.public_ip]
# }

resource "aws_route53_record" "harbor_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.moodlyharbor.click"
  type    = "A"

  alias {
    name                   = aws_lb.harbor_alb.dns_name
    zone_id                = aws_lb.harbor_alb.zone_id
    evaluate_target_health = true
  }
}
# --> 나중에 이거 쓸것!

resource "aws_route53_record" "acm_validation_www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_49d655e3213f066f19075e2da006a057.www.moodlyharbor.click."
  type    = "CNAME"
  ttl     = 300
  records = ["_52feb0e3019f142da9ea357e567387f2.xlfgrmvvlj.acm-validations.aws."]
}