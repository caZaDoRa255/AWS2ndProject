resource "kubernetes_deployment" "fastapi" {
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
            container_port = 8080
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
  depends_on = [null_resource.get_gke_credentials]

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
      target_port = 8080
    }

    type = "LoadBalancer"
  }
  depends_on = [null_resource.get_gke_credentials]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

resource "kubernetes_ingress_v1" "fastapi_ingress" {
  metadata {
    name = "fastapi-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "gce"
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
  }
  depends_on = [null_resource.get_gke_credentials]
}
