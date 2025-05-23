resource "incus_network" "colosseum-network" {
  name = "colosseum-network"
  type = "ovn"

  config = {
    "ipv4.address" = "10.254.0.2/8"
    "ipv4.nat" = "false"
    "ipv4.dhcp" = "false"
    "ipv6.address" = "none"
    "network" = "none"
  }
}

resource "incus_network_forward" "colosseum-vpn-forward" {
  network = "incusbr0"
  listen_address = var.cluster_address

  ports = concat(
    [
      {
        description = "Wireguard Forward"
        protocol = "udp"
        listen_port = "51820"
        target_address = "172.16.0.2"
        target_port = "51820"
      }
    ],
  )
}
