resource "incus_network" "colosseum-network" {
  name = "colosseum-network"
  type = "ovn"

  config = {
    "bridge.mtu" = "1300"
    "ipv4.address" = "10.254.0.2/8"
    "ipv4.nat" = "false"
    "ipv4.dhcp" = "false"
    "ipv6.address" = "none"
    "network" = "none"
  }
}

resource "incus_network" "colosseum_wan" {
  count  = length(var.nodes) == 1 ? 1 : 0
  name = "colosseum-wan"
  type = "bridge"

  config = {
    "ipv4.address" = "192.168.45.1/23"
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "ipv6.address" = "none"
  }
}

resource "incus_network" "colosseum_wan_node" {
  for_each = length(var.nodes) > 2 ? toset(var.nodes) : toset([])
  name = "colosseum-wan"
  type = "bridge"
  target = each.value
}

resource "incus_network" "colosseum_wan_cluster" {
  count  = length(var.nodes) > 1 ? 1 : 0
  name = "colosseum-wan"
  type = "bridge"

  config = {
    "ipv4.address" = "192.168.45.1/23"
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "ipv6.address" = "none"
  }
  depends_on = [incus_network.colosseum_wan_node]
}

resource "incus_network_forward" "colosseum-vpn-forward" {
  network = "colosseum-wan"
  listen_address = var.cluster_address

  ports = concat(
    [
      {
        description = "Wireguard Forward"
        protocol = "udp"
        listen_port = "51820"
        target_address = "192.168.45.2"
        target_port = "51820"
      }
    ],
  )

  depends_on = [
    incus_network.colosseum_wan,
    incus_network.colosseum_wan_cluster
  ]
}
