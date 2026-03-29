module "networks" {
  source = "./modules/networks"

  cluster_address = var.cluster_address
  nodes           = var.nodes
}

module "storage" {
  source = "./modules/storage"

  nodes        = var.nodes
}

module "profile" {
  source = "./modules/profile"

  depends_on  = [module.storage, module.networks]
}

# resource "terraform_data" "images" {
#   depends_on = [module.storage, module.networks]
# 
#   provisioner "local-exec" {
#     command = "packer init . && packer build ."
#     working_dir = "../../../../../packer/templates/"
#   }
#   
# }
# 
# module "instances" {
#   source     = "./modules/instances"
#   depends_on = [terraform_data.images]
# 
#   instance_type = var.instances_type
#   teams         = concat(["nop"], var.teams)
#   project_name  = var.project_name
# }
