variable "cluster_address" {
  type = string
}

variable "nodes" {
  type        = list(string)
  description = "List of nodes of the cluster"
}
