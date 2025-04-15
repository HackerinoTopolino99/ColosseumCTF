source "incus" "gameserver" {
  image = "images:debian/12"
  output_image = "gameserver"
  container_name = "${local.config.incus_cluster.remote}:gameserver"
  reuse = true
  publish_remote_name = local.config.incus_cluster.remote

  publish_properties =  {
    description = "Image for the gameserver"
  }
}

build {
  sources = ["source.incus.gameserver"]

  provisioner "shell" {
    inline  = [
      "echo 'deb-src http://deb.debian.org/debian bookworm main non-free-firmware' >> /etc/apt/sources.list",
      "apt-get update -y",
      "apt-get install -y apt-utils",
      "apt-get upgrade -y",
      "apt-get install -y bash-completion openssh-server python3 python-is-python3 sudo"
    ]
  }
}
