provider "google" {
  credentials = file("credentials.json")
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}
