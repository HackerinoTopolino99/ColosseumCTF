resource "incus_instance" "gameserver" {
  name  = "gameserver"
  image = "gameserver-image"
  profiles = ["colosseum-profile"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      name = "game"
      network = "colosseum-network"
      hwaddr = "02:12:99:00:00:00"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "colosseum-wan"
      "ipv4.address" = "192.168.44.3"
    }
  }
}

resource "incus_instance" "vulnbox" {
  count = length(var.teams)

  name  = "${var.teams[count.index]}-vulnbox"
  image = "vulnbox-image"
  profiles = ["colosseum-profile"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
    "security.nesting" = true
    "security.syscalls.intercept.mknod" = true
    "security.syscalls.intercept.setxattr" = true
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      name = "game"
      network = "colosseum-network"
      hwaddr = format("12:15:99:00:00:%02x", count.index)
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "colosseum-wan"
      "ipv4.address" = "192.168.45.${count.index + 1}"
    }
  }
}

resource "incus_instance" "router" {
  name  = "router"
  image = "router-image"
  profiles = ["colosseum-profile"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "colosseum-wan"
      "ipv4.address" = "192.168.44.2"
    }
  }
}
