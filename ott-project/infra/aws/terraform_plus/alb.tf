resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "harbor_alb" {
  name               = "harbor-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets # 퍼블릭 서브넷 2개 이상

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "harbor_tg" {
  name     = "harbor-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.harbor_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-2:979202697408:certificate/0d77d7d5-6e0f-4fed-8e8c-effa7e3b23a0"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.harbor_tg.arn
  }
}

resource "aws_lb_listener" "http_redirect_listener" {
  load_balancer_arn = aws_lb.harbor_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

#--> 이거 써라!
resource "aws_lb_target_group_attachment" "harbor_attachment" {
  target_group_arn = aws_lb_target_group.harbor_tg.arn
  target_id        = aws_instance.bastion.id  # EC2 인스턴스 ID
  port             = 80
}