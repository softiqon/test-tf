variable "name" {
  description = "Virtual network name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

variable "address_space" {
  description = "Address spaces (CIDR) for the VNet."
  type        = set(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for c in var.address_space : can(cidrhost(c, 0))])
    error_message = "address_space must contain at least one valid CIDR."
  }
}

variable "resource_group_id" {
  description = "Resource ID of the parent resource group."
  type        = string

}

variable "lock" {
  description = "Controls the Resource Lock configuration for this resource. The following properties can be specified: - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`. - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource."
  type = object({
    kind = string 
    name = optional(string, null) 
  })
}