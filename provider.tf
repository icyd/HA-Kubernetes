provider "google" {
  credentials = file("kubespray.json")
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}
