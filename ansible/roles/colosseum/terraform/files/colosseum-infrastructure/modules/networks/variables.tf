variable "cluster_address" {
  type = string
}

variable "nodes" {
  description = "List of nodes of the cluster"
  type = list(string)
}
