source "incus" "wireguard" {
  image = "images:alpine/3.20"
  output_image = "wireguard"
  container_name = "${local.config.incus_cluster.remote}:wireguard"
  reuse = true
  publish_remote_name = local.config.incus_cluster.remote

  publish_properties =  {
    description = "Image for the VPNs servers that will give access to the players to the infrastructure" 
  }
}

build {
  sources = ["source.incus.wireguard"]

  provisioner "shell" {
    inline  = [
      "apk add iptables wireguard-tools-wg-quick python3 bash-completion",
      "mkdir /etc/wireguard"
    ]
  }
}
