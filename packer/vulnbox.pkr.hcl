source "incus" "vulnbox-image" {
  image               = "images:debian/13/cloud"
  output_image        = "vulnbox-image"
  container_name      = "${var.remote}:vulnbox-image-build"
  reuse               = true
  publish_remote_name = var.remote
  virtual_machine     = var.virtual_machine

  publish_properties = {
    description = "Image for the servers where the vulnerable services will be hosted"
  }

  launch_config = {
    "security.nesting"                     = true
    "security.syscalls.intercept.mknod"    = true
    "security.syscalls.intercept.setxattr" = true
  }
}

build {
  sources = ["source.incus.vulnbox-image"]

  provisioner "shell" {
    inline = [
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y python3 cron vim tcpdump tmux bash-completion openssh-server nano file util-linux openssh-sftp-server htop ncdu ca-certificates curl ncurses-term",
      "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config"
    ]
  }

  provisioner "file" {
    source      = "${abspath(path.root)}/build_files/vulnbox/files/game.network"
    destination = "/etc/systemd/network/game.network"
  }

  provisioner "shell" {
    inline = [
      "chown -R systemd-network:systemd-network /etc/systemd/network/game.network",
      "chmod 644 /etc/systemd/network/game.network"
    ]
  }

  provisioner "file" {
    source      = "${abspath(path.root)}/build_files/vulnbox/files/services/"
    destination = "root"
  }

  provisioner "shell" {
    inline = [
      "chown -R root:root /root",
    ]
  }

  provisioner "shell" {
    script = "${abspath(path.root)}/build_files/vulnbox/scripts/install_docker.sh"
  }

  provisioner "shell" {
    script = "${abspath(path.root)}/build_files/vulnbox/scripts/setup_services.sh"
  }

  provisioner "shell" {
    inline = [
      "cloud-init clean --logs",
      "rm -rf /etc/machine-id /var/lib/dbus/machine-id",
      "touch /etc/machine-id"
    ]
  }
}
