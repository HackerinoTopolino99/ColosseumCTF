resource "incus_network" "colosseum-network" {
  name = "colosseum-network"
  type = var.network_type

  config = {
    "ipv4.address" = "10.254.0.1/8"
    "ipv4.nat" = "true"
    "ipv4.dhcp" = "true"
    "network" = "incusbr0"
  }
}

resource "incus_network_forward" "colosseum-forward" {
  network = "incusbr0"
  listen_address = var.cluster_address

  ports = [
    for i in range(length(var.teams)) : {
      description = "ciao2"
      protocol = "udp"
      listen_port = "${51820+i}"
      target_address = "172.16.252.3"
      target_port = "${51820+i}"
    }
  ]
}

resource "incus_network_forward" "wireguard-forward" {
  network = incus_network.colosseum-network.name
  listen_address = "172.16.252.3"

  ports = [
    for i in range(length(var.teams)) : {
      description = "ciao"
      protocol = "udp"
      listen_port = "${51820+i}"
      target_address = "10.80.${i}.1"
      target_port = "51820"
    }
  ]
}
