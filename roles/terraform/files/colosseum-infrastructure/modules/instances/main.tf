resource "incus_instance" "router" {
  count = length(var.nodes) == 1 ? 1 : 0
  name  = "router"
  image = "router-image"
  type  = var.instance_type

  config = {
    "boot.autostart" = true
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = "colosseum-wan"
      "ipv4.address" = "192.168.44.2"
    }
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      name    = "eth1"
      network = "gameNet"
    }
  }

  device {
    name = "eth2"
    type = "nic"
    properties = {
      name    = "eth2"
      network = "vulnNet"
    }
  }
}

resource "incus_instance" "router-cluster" {
  count = length(var.nodes) > 2 ? 1 : 0
  name  = "router"
  image = "router-image"
  type  = var.instance_type

  config = {
    "boot.autostart" = true
  }

  target = var.nodes[0]

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = "colosseum-wan"
      "ipv4.address" = "192.168.44.2"
    }
  }

  device {
    name = "eth1"
    type = "nic"
    properties = {
      name    = "eth1"
      network = "gameNet"
    }
  }

  device {
    name = "eth2"
    type = "nic"
    properties = {
      name    = "eth2"
      network = "vulnNet"
    }
  }
}

resource "incus_instance" "gameserver" {
  name       = "gameserver"
  image      = "gameserver-image"
  type       = var.instance_type
  depends_on = [incus_instance.router]

  config = {
    "boot.autostart" = true
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      name    = "game"
      network = "gameNet"
      hwaddr  = "02:12:99:00:00:00"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "colosseum-wan"
    }
  }
}

resource "incus_instance" "vulnbox" {
  count = length(var.teams)

  name       = "${var.teams[count.index]}-vulnbox"
  image      = "vulnbox-image"
  type       = var.instance_type
  depends_on = [incus_instance.router]

  config = {
    "boot.autostart"                       = true
    "security.nesting"                     = true
    "security.syscalls.intercept.mknod"    = true
    "security.syscalls.intercept.setxattr" = true
  }

  device {
    name = "game"
    type = "nic"
    properties = {
      name    = "game"
      network = "vulnNet"
      hwaddr  = format("12:15:99:00:00:%02x", count.index)
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "colosseum-wan"
    }
  }
}
