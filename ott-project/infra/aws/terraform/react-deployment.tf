# AWS EKS에서 React 앱 배포 설정

# EKS 클러스터 준비 확인
resource "null_resource" "eks_ready" {
  depends_on = [aws_eks_cluster.ott_eks, aws_eks_node_group.ott_node_group]

  provisioner "local-exec" {
    interpreter = ["cmd", "/c"]
    command = "aws eks update-kubeconfig --region ap-northeast-2 --name ott-eks"
  }

  provisioner "local-exec" {
    interpreter = ["cmd", "/c"]
    command = "kubectl wait --for=condition=ready nodes --all --timeout=300s"
  }
}

# React 앱을 위한 Kubernetes Deployment
resource "kubernetes_deployment" "react_app" {
  depends_on = [null_resource.eks_ready]
  
  metadata {
    name = "react-app"
    labels = {
      app = "react-app"
    }
    namespace = "default"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "react-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "react-app"
        }
      }

      spec {
        container {
          name  = "react-app"
          image = "huntress255/team4:beta"
          port {
            container_port = 80
          }
          env {
            name  = "VITE_API_URL"
            value = "http://backend.moodlyharbor.link"
          }
          env {
            name  = "PORT"
            value = "80"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# React 앱을 위한 Kubernetes Service
resource "kubernetes_service" "react_app_service" {
  depends_on = [null_resource.eks_ready]
  
  metadata {
    name = "react-app-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "react-app"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

# React 앱을 위한 Ingress
resource "kubernetes_ingress_v1" "react_ingress" {
  depends_on = [null_resource.eks_ready]
  
  metadata {
    name = "react-ingress"
    namespace = "default"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.react_app_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Ingress의 Load Balancer 주소를 가져오는 데이터 소스
data "kubernetes_ingress_v1" "react_ingress_status" {
  depends_on = [kubernetes_ingress_v1.react_ingress]
  
  metadata {
    name = "react-ingress"
    namespace = "default"
  }
}

# Ingress Load Balancer 주소를 기다리는 리소스
resource "null_resource" "wait_for_ingress_address" {
  depends_on = [kubernetes_ingress_v1.react_ingress]

  provisioner "local-exec" {
    interpreter = ["cmd", "/c"]
    command = <<-EOT
      echo "⏳ Ingress Load Balancer 주소 대기 중..."
      timeout 300 kubectl wait --for=condition=ready ingress/react-ingress --timeout=300s
      echo "✅ Ingress Load Balancer 준비 완료!"
    EOT
  }
}

# React 앱을 위한 Route 53 A 레코드 (Ingress Load Balancer 주소 사용)
# resource "aws_route53_record" "react_frontend" {
#   depends_on = [null_resource.wait_for_ingress_address]
#   
#   zone_id = data.aws_route53_zone.link.zone_id
#   name    = "frontend.moodlyharbor.link"
#   type    = "A"
#
#   alias {
#     name                   = data.kubernetes_ingress_v1.react_ingress_status.status[0].load_balancer[0].ingress[0].hostname
#     zone_id                = "Z14GRHDCWA56QT"
#     evaluate_target_health = true
#   }
# }

# 배포 상태 확인
resource "null_resource" "deployment_status_check" {
  depends_on = [
    kubernetes_deployment.react_app,
    kubernetes_service.react_app_service,
    kubernetes_ingress_v1.react_ingress
  ]

  provisioner "local-exec" {
    interpreter = ["cmd", "/c"]
    command = <<-EOT
      echo "📊 React 앱 배포 상태 확인 중..."
      kubectl get pods -l app=react-app
      kubectl get svc -l app=react-app
      kubectl get ingress react-ingress
      echo "✅ React 앱 배포 완료!"
      echo "🌐 접속 URL: http://frontend.moodlyharbor.link"
      echo "🔗 Load Balancer: $(kubectl get ingress react-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    EOT
  }
} 