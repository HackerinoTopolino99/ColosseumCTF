provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  default_remote               = var.remote

  remote {
    address  = "https://${var.cluster_address}:8443"
    name     = var.remote
    protocol = "incus"
  }
}
