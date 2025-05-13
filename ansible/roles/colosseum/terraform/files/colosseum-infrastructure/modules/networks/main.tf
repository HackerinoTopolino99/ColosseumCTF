resource "incus_network" "colosseum-network" {
  name = "colosseum-network"
  type = var.network_type

  config = {
    "ipv4.address" = "10.0.0.0/8"
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}

resource "incus_network_forward" "wireguard-forward" {
  count = length(var.teams)

  network = incus_network.colosseum-network
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
