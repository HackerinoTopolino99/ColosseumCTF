resource "incus_profile" "colosseum-profile" {
  name = "colosseum-profile"

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "colosseum-pool"
      path = "/"
    }
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      name    = "eth0"
      parent  = "colosseum-wan"
      nictype = "bridged"
    }
  }

  device {
    name = "game"
    type = "nic"

    properties = {
      name    = "game"
      network = "colosseum-network"
    }
  }
}

