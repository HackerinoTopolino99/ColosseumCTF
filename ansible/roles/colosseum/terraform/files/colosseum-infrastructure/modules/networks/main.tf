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

resource "incus_network_forward" "colosseum-forward" {
  network = "incusbr0"
  listen_address = var.cluster_address

  ports = concat(
    [
      {
        description = "ciao2"
        protocol = "udp"
        listen_port = "51820"
        target_address = "172.16.252.3"
        target_port = "51820"
      }
    ],
    [
      {
        description = "Gameserver forward"
        protcol = "tcp"
        listen_port = "80"
        target_address = "172.16.252.3"
        target_port = "80"
      }
    ]
  )
}

resource "incus_network_forward" "wireguard-forward" {
  network = incus_network.colosseum-network.name
  listen_address = "172.16.252.3"

  ports = concat(
    [
      {
        description = "ciao"
        protocol = "udp"
        listen_port = "51820"
        target_address = "10.254.0.1"
        target_port = "51820"
      }
    ],
    [
      {
        description = "Gameserver forward"
        protcol = "tcp"
        listen_port = "80"
        target_address = "10.10.0.1"
        target_port = "80"
      }
    ]
  )
}
