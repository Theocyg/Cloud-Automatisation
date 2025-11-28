output "load_balancer_ip" {
  value = google_compute_instance.load_balancer.network_interface.0.access_config.0.nat_ip
  description = "IP Publique du Load Balancer"
}

output "web_servers_ips" {
  value = google_compute_instance.web_server.*.network_interface.0.access_config.0.nat_ip
  description = "IPs Publiques des Web Servers"
}

output "app_servers_ips" {
  value = google_compute_instance.app_server.*.network_interface.0.access_config.0.nat_ip
  description = "IPs Publiques des App Servers"
}

output "db_servers_ips" {
  value = google_compute_instance.db_server.*.network_interface.0.access_config.0.nat_ip
  description = "IPs Publiques des DB Servers"
}
