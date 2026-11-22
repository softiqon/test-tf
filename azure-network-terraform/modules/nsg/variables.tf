variable "name" {
  description = "NSG name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "rules" {
  description = "Security rules keyed by rule name."
  type = map(object({
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = optional(string, "Tcp")
    source_port_range            = optional(string, "*")
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.rules : r.priority >= 100 && r.priority <= 4096])
    error_message = "Rule priority must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for r in var.rules : contains(["Inbound", "Outbound"], r.direction) && contains(["Allow", "Deny"], r.access)])
    error_message = "direction must be Inbound/Outbound and access must be Allow/Deny."
  }

  validation {
    condition     = length(distinct([for r in var.rules : "${r.direction}-${r.priority}"])) == length(var.rules)
    error_message = "Each rule needs a unique priority per direction."
  }
}

variable "diagnostics" {
  description = "Send NSG logs to Log Analytics. null disables."
  type = object({
    log_analytics_workspace_id = string
  })
  default = null
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
