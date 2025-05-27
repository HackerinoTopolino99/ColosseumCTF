resource "incus_instance" "gameserver" {
  name  = "gameserver"
  image = "gameserver-image"
  profiles = ["colosseum-profile"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
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
      "ipv4.address" = "192.168.45.2"
    }
  }
} 
