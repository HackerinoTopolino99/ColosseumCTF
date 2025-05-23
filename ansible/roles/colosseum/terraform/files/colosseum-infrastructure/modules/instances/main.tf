resource "incus_instance" "gameserver" {
  name  = "gameserver"
  image = "gameserver"
  profiles = ["default"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
  }

  device {
    name = "eth0"
    type = "nic"
    
    properties = {
      network = "incusbr0"
    }
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      "name" = "game"
      "network" = "colosseum-network"
    }
  }
}

resource "incus_instance" "vulnbox" {
  count = length(var.teams)

  name  = "${var.teams[count.index]}-vulnbox"
  image = "vulnbox"
  profiles = ["default"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
    "security.nesting" = true
    "security.syscalls.intercept.mknod" = true
    "security.syscalls.intercept.setxattr" = true
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "incusbr0"
    }
 }

  device {
    name = "game"
    type = "nic"
    properties = {
      name = "game"
      network = "colosseum-network"
    }
  }
}

resource "incus_instance" "router" {
  name  = "router"
  image = "router"
  profiles = ["default"]
  type = var.instance_type

  config = {
    "boot.autostart" = true
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "incusbr0"
      "ipv4.address" = "172.16.0.2"
    }
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      name = "game"
      network = "colosseum-network"
    }
  }
} 
