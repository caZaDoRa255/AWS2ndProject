locals {
  # Docker auth 필드를 base64 인코딩
  docker_auth = base64encode(format("%s:%s", var.gitlab_username, var.gitlab_token))

  # .dockerconfigjson 전체 JSON 구조를 만듦
  # base64encode는 kubernetes provider가 처리하므로 여기서는 제거
  dockerconfigjson_content = jsonencode({
    auths = {
      "registry.gitlab.com" = {
        auth = local.docker_auth
      }
    }
  })
}

resource "kubernetes_secret" "gitlab_registry_secret" {
  metadata {
    name      = "gitlab-regcred"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = local.dockerconfigjson_content
  }

  depends_on = [null_resource.get_gke_credentials]
}