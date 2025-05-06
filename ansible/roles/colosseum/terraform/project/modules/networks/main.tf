resource "incus_network" "gameserver-network" {
  name = "gameserver-network"
  project = var.project_name
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
  project = var.project_name
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
  project = var.project_name
  type = var.network_type

  config = {
    "ipv4.address" = var.networks["vpn-servers-network"]
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}
