source "incus" "router-image" {
  image               = "images:alpine/3.20"
  output_image        = "router-image"
  container_name      = "${var.remote}:router-image-build"
  reuse               = true
  publish_remote_name = var.remote
  virtual_machine     = var.virtual_machine

  publish_properties = {
    description = "Image for the VPNs servers that will give access to the players to the infrastructure"
  }
}

build {
  sources = ["source.incus.router-image"]

  provisioner "shell" {
    inline = [
      "apk update",
      "apk upgrade",
      "apk add iptables wireguard-tools-wg-quick python3 bash-completion dnsmasq vim",
      "mkdir /etc/wireguard",
      "rc-update add iptables",
      "iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -d 10.60.0.0/16 -j SNAT --to-source 10.254.0.1",
      "iptables -t nat -A POSTROUTING -s 10.60.0.0/16 -d 10.60.0.0/16 -j SNAT --to-source 10.254.0.1",
      "iptables -t nat -A POSTROUTING -s 10.80.0.0/16 -d 10.60.0.0/16 -j SNAT --to-source 10.254.0.1",
      "rc-service iptables save",
      "rc-update add dnsmasq"
    ]
  }

  provisioner "file" {
    source      = "${abspath(path.root)}/build_files/router/files/interfaces"
    destination = "/etc/network/interfaces"
  }

  provisioner "file" {
    source      = "${abspath(path.root)}/build_files/router/files/dnsmasq.conf"
    destination = "/etc/dnsmasq.conf"
  }
}
