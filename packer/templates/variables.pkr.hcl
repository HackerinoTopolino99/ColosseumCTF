variable remote {
  type = string
  default = "local"
  description = "Incus remote name"
}

variable virtual_machine {
  type = bool
  default = false
  description = "Type of the image. True for virtual machines false for containers"
}
