resource "google_compute_instance" "master" {
  count = var.master_count

  depends_on     = [google_compute_subnetwork.subnet]
  name           = "master-${count.index}"
  machine_type   = "n1-standard-2"
  zone           = "${var.GCP_REGION}-b"
  can_ip_forward = false
  tags           = ["controlplane", "k8s", "master"]

  boot_disk {
    initialize_params {
      size  = "50"
      image = var.GCP_IMAGE
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = "10.0.0.${2 + count.index}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    ssh-keys = join("\n", [for user, key in var.ssh_keys : "${user}:${file(key)}"])
  }

  metadata_startup_script = file("scripts/startup_master.sh")
}

resource "google_compute_instance" "worker" {
  count = var.worker_count

  depends_on     = [google_compute_subnetwork.subnet]
  name           = "worker-${count.index}"
  machine_type   = "n1-standard-2"
  zone           = "${var.GCP_REGION}-b"
  can_ip_forward = false
  tags           = ["worker", "k8s"]

  boot_disk {
    initialize_params {
      size  = "50"
      image = var.GCP_IMAGE
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = "10.0.1.${2 + count.index}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    ssh-keys = join("\n", [for user, key in var.ssh_keys : "${user}:${file(key)}"])
  }

  metadata_startup_script = file("scripts/startup_worker.sh")
}

resource "google_compute_instance" "bastion" {
  depends_on     = [google_compute_subnetwork.subnet]
  name           = "bastion"
  machine_type   = "n1-standard-2"
  zone           = "${var.GCP_REGION}-b"
  can_ip_forward = true
  tags           = ["bastion", "k8s"]

  boot_disk {
    initialize_params {
      size  = "50"
      image = var.GCP_IMAGE
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = "10.0.2.8"
    access_config {
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    ssh-keys = join("\n", [for user, key in var.ssh_keys : "${user}:${file(key)}"])
  }

  metadata_startup_script = file("scripts/startup_bastion.sh")
}
