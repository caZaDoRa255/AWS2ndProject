# Harbor 설치 리소스 정의

resource "null_resource" "install_harbor" {
  depends_on = [aws_instance.bastion]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.bastion.public_ip
      private_key = file("C:/Users/sol/.ssh/kyes-key.pem")# 실제 사용중인 키 경로로 변경
    }

    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y docker",
      "sudo dnf install -y libxcrypt-compat || true",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",

      "cd /opt",
      "sudo wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz",
      "sudo tar xvf harbor-online-installer-v2.10.0.tgz",
      "cd harbor",

      "sudo cp harbor.yml.tmpl harbor.yml",
      "sudo sed -i \"s/^hostname: .*/hostname: ${aws_instance.bastion.public_ip}/\" harbor.yml",
      "sudo sed -i 's/^  port: 443/#  port: 443/' harbor.yml",
      "sudo sed -i 's/^https:/#https:/' harbor.yml",
      "sudo sed -i 's/^  certificate/#  certificate/' harbor.yml",
      "sudo sed -i 's/^  private_key/#  private_key/' harbor.yml",

      "sudo ./install.sh"
    ]
  }
}

# Route53 도메인

data "aws_route53_zone" "main" {
  name = "moodlyharbor.click"
}

resource "aws_route53_record" "bastion_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.moodlyharbor.click"
  type    = "A"
  ttl     = 300
  records = [aws_instance.bastion.public_ip]
}
