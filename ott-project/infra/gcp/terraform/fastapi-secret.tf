resource "kubernetes_secret" "fastapi_env" {
  provider = kubernetes.gke
  metadata {
    name      = "fastapi-env"
    namespace = "default"
  }
  data = {
    ACCESS_TOKEN_EXPIRE_MINUTES = var.access_token_expire_minutes
    REFRESH_TOKEN_EXPIRE_DAYS   = var.refresh_token_expire_days
    SECRET_KEY                  = var.secret_key
    DATABASE_URL                = "mysql+pymysql://${var.db_user}:${var.db_password}@${google_sql_database_instance.mysql_instance.private_ip_address}:3306/${var.db_name}"
    AWS_ACCESS_KEY_ID           = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY       = var.aws_secret_access_key
    AWS_REGION                  = var.aws_region
    S3_BUCKET_NAME              = var.s3_bucket_name
    GEMINI_API_KEY              = var.gemini_api_key
    FRONTEND_ORIGIN             = var.frontend_origin
  }
  type = "Opaque"
  depends_on = [null_resource.configure_kubectl]
}