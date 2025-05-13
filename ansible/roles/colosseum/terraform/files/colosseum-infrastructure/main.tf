provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true

  remote {
    name = var.remote
    scheme = "https"
    address = var.cluster_address
    default = true
  }
}

module "networks" {
  source = "./modules/networks"

  cluster_address = var.cluster_address
  teams = concat(["nop"], var.teams)
}

module "instances" {  
  source = "./modules/instances"
  depends_on = [module.networks]
  
  instance_type = var.instances_type
  teams = concat(["nop"], var.teams)
}
