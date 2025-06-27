resource "kubernetes_deployment" "fastapi" {
  metadata {
    name = "fastapi"
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
          image = var.fastapi_image  # 예: registry.gitlab.com/user/project:latest
          port {
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [null_resource.get_gke_credentials]
}

resource "kubernetes_service" "fastapi_service" {
  metadata {
    name = "fastapi-service"
  }

  spec {
    selector = {
      app = "fastapi"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "ClusterIP"
  }
  depends_on = [null_resource.get_gke_credentials]
}
