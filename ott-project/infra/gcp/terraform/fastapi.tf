resource "kubernetes_deployment" "fastapi" {
  provider = kubernetes.gke
  metadata {
    name = "fastapi-app"
    namespace = "default"
    labels = {
      app = "fastapi"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fastapi"
      }
    }

    template {
      metadata {
        labels = {
          app = "fastapi"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry_secret.metadata[0].name
        }

        container {
          name  = "fastapi"
          image = var.fastapi_image
          port {
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          
          env_from {
            secret_ref {
              name = kubernetes_secret.fastapi_env.metadata[0].name
            }
          }
        }
      }
    }
  }
  depends_on = [null_resource.configure_kubectl]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
      spec[0].template[0].metadata[0].annotations,
      spec[0].template[0].metadata[0].labels,
    ]
  }
}

resource "kubernetes_service" "fastapi_service" {
  provider = kubernetes.gke
  metadata {
    name = "fastapi-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "fastapi"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"  # 외부 접근을 위해 LoadBalancer 유지
  }
  depends_on = [null_resource.configure_kubectl]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "google_compute_address" "fastapi_ingress_ip" {
  name   = "fastapi-ingress-ip"
  region = var.region
}

resource "kubernetes_ingress_v1" "fastapi_ingress" {
  provider = kubernetes.gke
  metadata {
    name = "fastapi-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "gce"
      "networking.gke.io/managed-certificates" = "fastapi-cert"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_address.fastapi_ingress_ip.name
      "kubernetes.io/ingress.allow-http" = "true"
    }
  }
  spec {
    rule {
      host = "api.moodlyharbor.click"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.fastapi_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      hosts      = ["api.moodlyharbor.click"]
    }
  }
  depends_on = [null_resource.configure_kubectl]
}

resource "null_resource" "apply_managed_cert" {
  depends_on = [null_resource.configure_kubectl, kubernetes_ingress_v1.fastapi_ingress]
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<EOT
$yaml = @"
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: fastapi-cert
  namespace: default
spec:
  domains:
    - api.moodlyharbor.click
"@
$yaml | kubectl apply -f -
EOT
  }
}