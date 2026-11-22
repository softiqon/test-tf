variable "name" {
  description = "Virtual network name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the parent resource group."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.resource_group_id))
    error_message = "resource_group_id must be a resource group ID: /subscriptions/<sub>/resourceGroups/<rg>."
  }
}

variable "address_space" {
  description = "Address spaces (CIDR) for the VNet."
  type        = set(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for c in var.address_space : can(cidrhost(c, 0))])
    error_message = "address_space must contain at least one valid CIDR."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers. Empty list = Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "Optional DDoS protection plan ID."
  type        = string
  default     = null
}

variable "encryption_enforcement" {
  description = "Optional VNet encryption enforcement: AllowUnencrypted or DropUnencrypted. null disables encryption."
  type        = string
  default     = null

  validation {
    condition     = contains(["AllowUnencrypted", "DropUnencrypted"], coalesce(var.encryption_enforcement, "AllowUnencrypted"))
    error_message = "encryption_enforcement must be AllowUnencrypted or DropUnencrypted."
  }
}

variable "diagnostics" {
  description = "Send VNet diagnostics to Log Analytics. null disables."
  type = object({
    log_analytics_workspace_id = string
  })
  default = null
}

variable "enable_vm_protection" {
  description = "Enable VM protection on the VNet."
  type        = bool
  default     = false
}

variable "lock" {
  description = "Optional management lock (CanNotDelete or ReadOnly)."
  type = object({
    kind = string
    name = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "AVM telemetry."
  type        = bool
  default     = true
}
