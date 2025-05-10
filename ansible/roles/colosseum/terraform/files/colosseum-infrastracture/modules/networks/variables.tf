variable "networks" {
  description = "List of networks"
  type = map(string)
}

variable "network_type" {
  type = string
  default = "ovn"
}

locals {
  network_type = var.project_name != "default" ? "ovn" : var.network_type
}
