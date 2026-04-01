variable "teams" {
  type        = list(string)
  description = "List of teams that will partecipate"
}

variable "instance_type" {
  type    = string
  default = "container"

  validation {
    condition     = contains(["container", "virtual-machine"], var.instance_type)
    error_message = "The value must be container or virtual-machine"
  }
}

variable "nodes" {
  type        = list(string)
  description = "List of nodes of a cluster"
}
