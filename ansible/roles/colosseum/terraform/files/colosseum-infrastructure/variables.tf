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

variable "remote" {
  description = "Remote del progetto"
  type = string
}

variable "teams" {
  description = "List of teams that will partecipate"
  type = list(string)
}

variable "nodes" {
  description = "List of nodes of a cluster"
  type = list(string)
}
