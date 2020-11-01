resource "google_compute_instance_group" "master_nodes" {
  name      = "master-nodes"
  instances = [for i in google_compute_instance.master : i.id]
  named_port {
    name = "apiserver"
    port = "6443"
  }
  zone = google_compute_instance.master[0].zone
}

resource "google_compute_health_check" "healthz" {
  name = "healthz"
  tcp_health_check {
    port = "6443"
  }
}

resource "google_compute_region_backend_service" "apiserver" {
  name          = "apiserver"
  region        = var.GCP_REGION
  health_checks = [google_compute_health_check.healthz.id]
  backend {
    group          = google_compute_instance_group.master_nodes.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "apiserver" {
  name                  = "apiserver"
  region                = var.GCP_REGION
  load_balancing_scheme = "INTERNAL"
  network               = google_compute_network.vpc.name
  subnetwork            = google_compute_subnetwork.subnet.name
  backend_service       = google_compute_region_backend_service.apiserver.id
  ip_address            = "10.0.0.6"
  ip_protocol           = "TCP"
  ports                 = ["6443"]
}
