source "incus" "gameserver-image" {
  image               = "images:debian/13"
  output_image        = "gameserver-image"
  container_name      = "${var.remote}:gameserver-image-build"
  reuse               = true
  publish_remote_name = var.remote
  virtual_machine     = var.virtual_machine

  publish_properties = {
    description = "Image for the gameserver"
  }
}

build {
  sources = ["source.incus.gameserver-image"]

  provisioner "shell" {
    inline = [
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y bash-completion python3 python-is-python3 sudo",
    ]
  }

  provisioner "file" {
    source = "${path.root}/build_files/gameserver/files/game.network"
    destination = "/etc/systemd/network/game.network"
  }
}
