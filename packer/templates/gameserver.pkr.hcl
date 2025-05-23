source "incus" "gameserver" {
  image = "images:debian/12"
  output_image = "gameserver"
  container_name = "${var.remote}:gameserver"
  reuse = true
  publish_remote_name = var.remote
  virtual_machine = var.virtual_machine

  publish_properties =  {
    description = "Image for the gameserver"
  }
}

build {
  sources = ["source.incus.gameserver"]

  provisioner "shell" {
    inline  = [
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y bash-completion python3 python-is-python3 sudo"
    ]
  }
}
