variable "cluster_address" {
  description = "Public address of the cluster"
  type = string
}

variable "instances_type" {
  type = string
  default = "container"

  validation {
    condition = contains(["container", "virtual-machine"], var.instances_type)
    error_message = "The value must be container or virtual-machine"
  }
}

variable "networks" {
  description = "List of networks"
  type = map(string)
}

variable "remote" {
  description = "Remote del progetto"
  type = string
}

variable "teams" {
  description = "List of teams that will partecipate"
  type = list(string)
}
