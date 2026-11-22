variable "name" {
  description = "Route table name."
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

variable "bgp_route_propagation_enabled" {
  description = "Propagate gateway (BGP) routes. Usually false for spokes forced through a firewall."
  type        = bool
  default     = true
}

variable "routes" {
  description = "Routes keyed by route name."
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in var.routes : contains(["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"], r.next_hop_type)
    ])
    error_message = "next_hop_type must be VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance or None."
  }

  validation {
    condition = alltrue([
      for r in var.routes : r.next_hop_type != "VirtualAppliance" || can(cidrhost("${coalesce(r.next_hop_in_ip_address, "x")}/32", 0))
    ])
    error_message = "VirtualAppliance routes need a valid next_hop_in_ip_address."
  }
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
