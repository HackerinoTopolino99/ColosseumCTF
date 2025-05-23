source "incus" "router" {
  image = "images:alpine/3.20"
  output_image = "router"
  container_name = "${var.remote}:router"
  reuse = true
  publish_remote_name = var.remote
  virtual_machine = var.virtual_machine

  publish_properties =  {
    description = "Image for the VPNs servers that will give access to the players to the infrastructure" 
  }
}

build {
  sources = ["source.incus.router"]

  provisioner "shell" {
    inline  = [
      "apk update",
      "apk upgrade",
      "apk add iptables wireguard-tools-wg-quick python3 bash-completion dnsmasq",
      "mkdir /etc/wireguard",
      "rc-update add iptables",
    ]
  }
}
