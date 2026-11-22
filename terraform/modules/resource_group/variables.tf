variable "name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "lock" {
  description = "Optional lock. kind: CanNotDelete or ReadOnly."
  type = object({
    kind = string
    name = optional(string)
  })
  default = null
}