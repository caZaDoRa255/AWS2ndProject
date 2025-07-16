# Helm Provider 설정
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

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
  certificate_arn   = var.certificate_arn

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



# alb.tf
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

# React 앱을 위한 Target Group
resource "aws_lb_target_group" "react_app" {
  name        = "react-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

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


data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

  resource "aws_iam_policy" "alb_controller" {
    name   = "AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/iam_policy.json")
  }

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}



# Helm 릴리스를 사전에 정리하는 null_resource
resource "null_resource" "cleanup_existing_helm_release" {
  triggers = {
    # 항상 실행되도록 timestamp 사용
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      kubectl config use-context ${data.aws_eks_cluster.cluster.arn}
      
      # 모든 aws-load-balancer-controller 관련 릴리스 삭제
      $helmList = helm list -n kube-system --output json | ConvertFrom-Json
      foreach ($release in $helmList) {
        if ($release.name -like "*aws-load-balancer-controller*") {
          Write-Host "Deleting existing Helm release: $($release.name)"
          helm uninstall $release.name -n kube-system --timeout 5m
        }
      }
      
      # 관련 파드들도 강제 삭제
      $pods = kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --output json | ConvertFrom-Json
      foreach ($pod in $pods.items) {
        Write-Host "Force deleting pod: $($pod.metadata.name)"
        kubectl delete pod $pod.metadata.name -n kube-system --force --grace-period=0
      }
      
      # 파드가 완전히 삭제될 때까지 대기
      Start-Sleep -Seconds 15
      
      # 네임스페이스가 정리될 때까지 대기
      $retryCount = 0
      do {
        $pods = kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --output json | ConvertFrom-Json
        if ($pods.items.Count -eq 0) {
          Write-Host "All pods cleaned up successfully"
          break
        }
        Write-Host "Waiting for pods to be cleaned up... (attempt $retryCount)"
        Start-Sleep -Seconds 5
        $retryCount++
      } while ($retryCount -lt 12) # 최대 1분 대기
    EOT
  }

  depends_on = [aws_eks_cluster.ott_eks]
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    }
  ]

  timeout = 600  # timeout을 10분으로 늘림
  wait    = true

  depends_on = [aws_eks_cluster.ott_eks, aws_eks_node_group.ott_node_group, null_resource.cleanup_existing_helm_release]
}

# Terraform destroy 시 Helm 릴리스 정리
resource "null_resource" "cleanup_helm_on_destroy" {
  triggers = {
    # 항상 실행되도록 timestamp 사용
    timestamp = timestamp()
  }

  # Terraform destroy 시에만 실행
  provisioner "local-exec" {
    when    = destroy
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      try {
        # 현재 컨텍스트 사용
        $currentContext = kubectl config current-context
        Write-Host "Using context: $currentContext"
        
        # aws-load-balancer-controller 관련 모든 Helm 릴리스 삭제
        $helmList = helm list -n kube-system --output json | ConvertFrom-Json
        foreach ($release in $helmList) {
          if ($release.name -like "*aws-load-balancer-controller*") {
            Write-Host "Destroying Helm release: $($release.name)"
            try {
              helm uninstall $release.name -n kube-system --timeout 5m
            } catch {
              Write-Host "Warning: Failed to uninstall $($release.name): $_"
            }
          }
        }
        
        # 관련 시크릿들도 정리
        try {
          $secrets = kubectl get secrets -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --output json | ConvertFrom-Json
          foreach ($secret in $secrets.items) {
            Write-Host "Cleaning up secret: $($secret.metadata.name)"
            try {
              kubectl delete secret $secret.metadata.name -n kube-system --ignore-not-found=true
            } catch {
              Write-Host "Warning: Failed to delete secret $($secret.metadata.name): $_"
            }
          }
        } catch {
          Write-Host "Warning: Error during secret cleanup: $_"
        }
      } catch {
        Write-Host "Error during Helm cleanup: $_"
      }
    EOT
  }
}