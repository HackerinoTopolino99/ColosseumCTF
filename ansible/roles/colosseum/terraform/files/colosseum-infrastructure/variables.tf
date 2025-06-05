variable "cluster_address" {
  type        = string
  description = "Public address of the cluster"
}

variable "instances_type" {
  type        = string
  description = "Type of instances to use in the cluster. Possible values are 'container' or 'virtual-machine'."
  default     = "container"

  validation {
    condition     = contains(["container", "virtual-machine"], var.instances_type)
    error_message = "The value must be container or virtual-machine"
  }
}

variable "remote" {
  type        = string
  description = "Remote del progetto"
}

variable "teams" {
  type        = list(string)
  description = "List of teams that will partecipate"
}

variable "nodes" {
  type        = list(string)
  description = "List of nodes of a cluster"
}
