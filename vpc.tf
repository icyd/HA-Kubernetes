resource "google_compute_network" "vpc" {
  name                    = "k8s-cluster"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "k8s-subnet"
  region        = var.GCP_REGION
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.cidr
  depends_on    = [google_compute_network.vpc]
}

resource "google_compute_firewall" "worker-internal" {
  name    = "worker-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_tags = ["controlplane"]
  target_tags = ["worker"]
  depends_on  = [google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "worker-external" {
  name    = "worker-external"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["worker"]
  depends_on    = [google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "controlplane-apiserver" {
  name    = "controlplane-apiserver"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["53", "6443"]
  }

  source_ranges = [var.cidr]
  target_tags   = ["controlplane"]
  depends_on    = [google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "controlplane-internal" {
  name    = "controlplane-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250-10252", "2379-2380"]
  }

  source_tags = ["controlplane"]
  target_tags = ["controlplane"]
  depends_on  = [google_compute_subnetwork.subnet]
}

data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

resource "google_compute_firewall" "external-ssh" {
  name    = "bastion-external"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${data.http.myip.body}/32"]
  target_tags   = ["bastion"]
  depends_on    = [google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "internal-ssh" {
  name    = "controlplane-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["bastion"]
  target_tags = ["k8s"]
  depends_on  = [google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "cni" {
  name    = "cni"
  network = google_compute_network.vpc.name

  allow {
    protocol = "ipip"
  }

  allow {
    protocol = "esp"
  }

  allow {
    protocol = "tcp"
    ports    = ["179", "5473", "6781-6783"]
  }

  allow {
    protocol = "udp"
    ports    = ["4789", "6783-6784", "8285", "8472"]
  }

  source_tags = ["k8s"]
  target_tags = ["k8s"]
  depends_on  = [google_compute_subnetwork.subnet]
}
resource "google_compute_router" "default" {
  name    = "k8s-route"
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "k8s-nat"
  router                             = google_compute_router.default.name
  region                             = google_compute_router.default.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}
