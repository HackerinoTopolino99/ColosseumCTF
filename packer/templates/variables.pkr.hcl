variable remote {
  type        = string
  description = "Incus remote name"
  default     = "local"
}

variable virtual_machine {
  type        = bool
  description = "Type of the image. True for virtual machines false for containers"
  default     = false
}
