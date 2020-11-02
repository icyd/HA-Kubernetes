output "controlplane" {
  value = [for i in google_compute_instance.master : i.network_interface.0.access_config.0.nat_ip]
}

output "worker" {
  value = [for i in google_compute_instance.worker : i.network_interface.0.access_config.0.nat_ip]
}
