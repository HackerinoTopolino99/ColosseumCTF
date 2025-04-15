packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
    incus = {
      source  = "github.com/bketelsen/incus"
      version = "~> 1"
    }
  }
}