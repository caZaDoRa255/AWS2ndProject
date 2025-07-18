# output "gcp_vpn_ip" {
#   value = google_compute_address.vpn_static_ip.address
# }

# output "cloud_function_url" {
#   value = google_cloudfunctions2_function.hello_function.service_config[0].uri
# }

# Firestore 관련 출력
# output "firestore_database_name" {
#   description = "Firestore 데이터베이스 이름"
#   value       = google_firestore_database.database.name
# }

# output "firestore_database_location" {
#   description = "Firestore 데이터베이스 위치"
#   value       = google_firestore_database.database.location_id
# }

# output "firestore_database_type" {
#   description = "Firestore 데이터베이스 타입"
#   value       = google_firestore_database.database.type
# }

# FastAPI 서비스 외부 IP 출력
output "fastapi_external_ip" {
  description = "FastAPI 서비스의 외부 IP 주소"
  value       = kubernetes_service.fastapi_service.status[0].load_balancer[0].ingress[0].ip
}

