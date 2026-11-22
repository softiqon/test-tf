variable "subscription_id" {
  description = "Target subscription."
  type        = string
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "location_short" {
  type    = string
  default = "aue"
}

variable "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace for diagnostics. null disables."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "firewall_private_ip" {
  description = "Hub firewall/NVA private IP. Spokes default-route to it."
  type        = string
  default     = null
}

# Schemas enforced by patterns/hub-spoke.
variable "hub" {
  type = any
}

variable "spokes" {
  type    = any
  default = {}
}
