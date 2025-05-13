resource "incus_network" "gameserver-network" {
  name = "gameserver-network"
  type = var.network_type

  config = {
    "ipv4.address" = var.networks["gameserver-network"]
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}

resource "incus_network" "vulnboxes-network" {
  name = "vulnboxes-network"
  type = var.network_type

  config = {
    "ipv4.address" = var.networks["vulnboxes-network"]
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}

resource "incus_network" "vpn-servers-network" {
  name = "vpn-servers-network"
  type = var.network_type

  config = {
    "ipv4.address" = var.networks["vpn-servers-network"]
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}

resource "incus_network_forward" "wireguard-forward" {
  count = length(var.teams)

  network = incus_network.vpn-servers-network
  listen_address = var.cluster_address

  ports = [
    {
      description = "Wireguard"
      protocol = "udp"
      listen_port = "51820+count.index"
      target_address = "10.80.${count.index}.254"
      target_port = "51820"
    }
  ]
}
