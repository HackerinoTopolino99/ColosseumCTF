resource "incus_storage_pool" "colosseum_pool" {
  count  = length(var.nodes) == 1 ? 1 : 0
  name   = "colosseum-pool"
  driver = "dir"

  config = {
    source = "/var/lib/incus/storage-pools/colosseum-pool"
  }
}

resource "incus_storage_pool" "colosseum_pool_node" {
  for_each = length(var.nodes) > 1 ? toset(var.nodes) : toset([])
  name     = "colosseum-pool"
  driver   = "dir"

  target = trimspace(each.value)
}

resource "incus_storage_pool" "colosseum_pool_cluster" {
  count  = length(var.nodes) > 1 ? 1 : 0
  name   = "colosseum-pool"
  driver = "dir"

  depends_on = [incus_storage_pool.colosseum_pool_node]
}
