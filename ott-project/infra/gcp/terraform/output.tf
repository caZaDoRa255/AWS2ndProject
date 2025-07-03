# output "gcp_vpn_ip" {
#   value = google_compute_address.vpn_static_ip.address
# }

output "cloud_function_url" {
  value = google_cloudfunctions2_function.hello_function.service_config[0].uri
}
