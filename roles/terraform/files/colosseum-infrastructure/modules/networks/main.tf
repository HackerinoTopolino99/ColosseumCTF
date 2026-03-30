resource "incus_network" "gameNet" {
  count = length(var.nodes) == 1 ? 1 : 0
  name  = "gameNet"
  type  = "bridge"

  config = {
    "ipv4.address" = "none"
    "ipv4.nat"     = "false"
    "ipv4.dhcp"    = "false"
    "ipv6.address" = "none"
  }
}

resource "incus_network" "gameNet-node" {
  for_each = length(var.nodes) > 2 ? toset(var.nodes) : toset([])
  name     = "gameNet"
  type     = "bridge"
  target   = each.value

}

resource "incus_network" "gameNet-cluster" {
  count = length(var.nodes) > 1 ? 1 : 0
  name  = "gameNet"
  type  = "bridge"

  depends_on = [incus_network.gameNet-node]

  config = {
    "bridge.mtu"             = "1450"
    "ipv4.address"           = "none"
    "ipv4.dhcp"              = "false"
    "ipv4.nat"               = "false"
    "ipv6.address"           = "none"
    "tunnel.vxlan0.group"    = "239.0.0.1"
    "tunnel.vxlan0.protocol" = "vxlan"
    "tunnel.vxlan0.port"     = "4789"
    "tunnel.vxlan0.id"       = "1"
  }
}

resource "incus_network" "vulnNet" {
  count = length(var.nodes) == 1 ? 1 : 0
  name  = "vulnNet"
  type  = "bridge"

  config = {
    "ipv4.address" = "none"
    "ipv4.nat"     = "false"
    "ipv4.dhcp"    = "false"
    "ipv6.address" = "none"
  }
}

resource "incus_network" "vulnNet-node" {
  for_each = length(var.nodes) > 2 ? toset(var.nodes) : toset([])
  name     = "vulnNet"
  type     = "bridge"
  target   = each.value
}

resource "incus_network" "vulnNet-cluster" {
  count = length(var.nodes) > 1 ? 1 : 0
  name  = "vulnNet"
  type  = "bridge"

  depends_on = [incus_network.vulnNet-node]

  config = {
    "bridge.mtu"             = "1450"
    "ipv4.address"           = "none"
    "ipv4.dhcp"              = "false"
    "ipv4.nat"               = "false"
    "ipv6.address"           = "none"
    "tunnel.vxlan1.group"    = "239.0.0.2"
    "tunnel.vxlan1.protocol" = "vxlan"
    "tunnel.vxlan1.port"     = "4789"
    "tunnel.vxlan1.id"       = "2"
  }
}

resource "incus_network" "colosseum-wan" {
  count = length(var.nodes) == 1 ? 1 : 0
  name  = "colosseum-wan"
  type  = "bridge"

  config = {
    "ipv4.address"     = "192.168.44.1/23"
    "ipv4.nat"         = "true"
    "ipv4.dhcp"        = "true"
    "ipv4.dhcp.ranges" = "192.168.44.1-192.168.45.254"
    "ipv6.address"     = "none"
    "raw.dnsmasq"      = "dhcp-option=1,255.255.255.255"
  }
}

resource "incus_network" "colosseum-wan-node" {
  for_each = length(var.nodes) > 2 ? toset(var.nodes) : toset([])
  name     = "colosseum-wan"
  type     = "bridge"
  target   = each.value
}

resource "incus_network" "colosseum-wan-cluster" {
  count = length(var.nodes) > 1 ? 1 : 0
  name  = "colosseum-wan"
  type  = "bridge"

  config = {
    "ipv4.address"     = "192.168.44.1/23"
    "ipv4.nat"         = "true"
    "ipv4.dhcp"        = "true"
    "ipv4.dhcp.ranges" = "192.168.44.1-192.168.45.254"
    "ipv6.address"     = "none"
    "raw.dnsmasq"      = "dhcp-option=1,255.255.255.255"
  }
  depends_on = [incus_network.colosseum-wan-node]
}

resource "incus_network_forward" "colosseum-vpn-forward" {
  network        = "colosseum-wan"
  listen_address = var.cluster_address

  ports = concat(
    [
      {
        description    = "Wireguard Forward"
        protocol       = "udp"
        listen_port    = "51820"
        target_address = "192.168.44.2"
        target_port    = "51820"
      }
    ],
  )

  depends_on = [
    incus_network.colosseum-wan,
    incus_network.colosseum-wan-cluster
  ]
}
