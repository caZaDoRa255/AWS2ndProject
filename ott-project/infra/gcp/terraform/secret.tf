resource "kubernetes_secret" "gitlab_registry_secret" {
  metadata {
    name      = "gitlab-regcred"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = base64encode(jsonencode({
      auths = {
        "registry.gitlab.com" = {
          username = var.gitlab_username
          password = var.gitlab_token
          email    = "none@example.com"
        }
      }
    }))
  }
}
