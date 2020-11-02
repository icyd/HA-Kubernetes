variable "GCP_PROJECT_ID" {
  description = "GCP project id."
  default     = "kubespray-294313"
}

variable "GCP_REGION" {
  description = "GCP Region where the cluster will be deployed."
  default     = "us-east1"
}

variable "GCP_ZONE" {
  description = "Zone where the cluster will be deployed."
  default     = "b"
}

variable "GCP_IMAGE" {
  description = "Compute instance image."
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "master_count" {
  description = "Number of master nodes."
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes."
  default     = 1
}

variable "cidr" {
  description = "CIDR block for the cluster network."
  default     = "10.0.0.0/16"
}

variable "ssh_keys" {
  description = "Name of the public ssh key file."
  default = {
    "admin" = "ssh_key.pub"
  }
}

variable "bastion_enabled" {
  description = "Whether or not to deploy bastion host."
  default     = false
}
