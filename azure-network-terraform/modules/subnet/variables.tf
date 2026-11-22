variable "name" {
  description = "Subnet name."
  type        = string
}

variable "virtual_network_id" {
  description = "Parent VNet resource ID."
  type        = string
}

variable "location" {
  description = "Region (used by AVM telemetry)."
  type        = string
}

variable "address_prefixes" {
  description = "Subnet CIDRs."
  type        = list(string)

  validation {
    condition     = length(var.address_prefixes) > 0 && alltrue([for c in var.address_prefixes : can(cidrhost(c, 0))])
    error_message = "address_prefixes must contain at least one valid CIDR."
  }
}

# Objects (not bare IDs) so null-ness is known at plan time even when the ID is not.
variable "network_security_group" {
  description = "NSG to associate: { id = ... } or null."
  type        = object({ id = string })
  default     = null
}

variable "route_table" {
  description = "Route table to associate: { id = ... } or null."
  type        = object({ id = string })
  default     = null
}

variable "nat_gateway" {
  description = "NAT gateway to associate: { id = ... } or null."
  type        = object({ id = string })
  default     = null
}

variable "service_endpoints" {
  description = "Service endpoints, e.g. Microsoft.Storage."
  type        = set(string)
  default     = []
}

variable "delegations" {
  description = "Subnet delegations, e.g. { name = \"webapp\", service = \"Microsoft.Web/serverFarms\" }."
  type = list(object({
    name    = string
    service = string
  }))
  default = []
}

variable "private_endpoint_network_policies" {
  description = "Disabled | Enabled | NetworkSecurityGroupEnabled | RouteTableEnabled."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], var.private_endpoint_network_policies)
    error_message = "Invalid private_endpoint_network_policies value."
  }
}

variable "default_outbound_access_enabled" {
  description = "Implicit internet egress. Keep false (secure default); use NAT GW / firewall instead. Create-time only."
  type        = bool
  default     = false
}

variable "enable_telemetry" {
  description = "AVM telemetry."
  type        = bool
  default     = true
}
