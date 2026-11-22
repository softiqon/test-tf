# ---------- shared ----------
variable "environment" {
  description = "Environment short name, e.g. prod."
  type        = string
}

variable "location" {
  description = "Azure region for hub and spokes."
  type        = string
}

variable "location_short" {
  description = "Region abbreviation, e.g. aue."
  type        = string
}

variable "diagnostics" {
  description = "Log Analytics destination for all VNets/NSGs. null disables."
  type = object({
    log_analytics_workspace_id = string
  })
  default = null
}

variable "firewall_private_ip" {
  description = "Private IP of the hub firewall / NVA. When set, spokes with route_via_hub = true get a 0.0.0.0/0 UDR to it."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

# ---------- hub ----------
variable "hub" {
  description = "Hub VNet definition."
  type = object({
    workload              = optional(string, "hub")
    name                  = optional(string)
    resource_group_name   = string
    create_resource_group = optional(bool, true)
    address_space         = set(string)
    dns_servers           = optional(list(string), [])
    has_gateway           = optional(bool, false) # VPN/ExpressRoute gateway present -> spokes use it
    ddos_protection_plan_id = optional(string)
    route_tables          = optional(map(object({
      name                          = optional(string)
      bgp_route_propagation_enabled = optional(bool, true)
      routes = optional(map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      })), {})
    })), {})
    subnets               = optional(map(object({
      name             = optional(string) # default: snet-<key>. Set exactly for GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet...
      address_prefixes = list(string)
      create_nsg       = optional(bool, true)
      nsg_rules = optional(map(object({
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
      })), {})
      route_table_key   = optional(string)
      nat_gateway_id    = optional(string)
      service_endpoints = optional(set(string), [])
      delegations = optional(list(object({
        name    = string
        service = string
      })), [])
      private_endpoint_network_policies = optional(string, "Enabled")
      default_outbound_access_enabled   = optional(bool, false)
    })), {})
  })
}

# ---------- spokes ----------
variable "spokes" {
  description = "Spoke VNets keyed by workload name. Add an entry to add a spoke."
  type = map(object({
    name                  = optional(string)
    resource_group_name   = optional(string) # default: rg-<key>-network-<env>-<region>
    create_resource_group = optional(bool, true)
    address_space         = set(string)
    dns_servers           = optional(list(string)) # null = inherit hub DNS servers
    route_via_hub         = optional(bool, true)   # force 0.0.0.0/0 to firewall_private_ip
    route_tables          = optional(map(object({
      name                          = optional(string)
      bgp_route_propagation_enabled = optional(bool, true)
      routes = optional(map(object({
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      })), {})
    })), {})
    subnets               = optional(map(object({
      name             = optional(string) # default: snet-<key>. Set exactly for GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet...
      address_prefixes = list(string)
      create_nsg       = optional(bool, true)
      nsg_rules = optional(map(object({
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
      })), {})
      route_table_key   = optional(string)
      nat_gateway_id    = optional(string)
      service_endpoints = optional(set(string), [])
      delegations = optional(list(object({
        name    = string
        service = string
      })), [])
      private_endpoint_network_policies = optional(string, "Enabled")
      default_outbound_access_enabled   = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition     = length(distinct(flatten([for s in var.spokes : tolist(s.address_space)]))) == length(flatten([for s in var.spokes : tolist(s.address_space)]))
    error_message = "Spoke address spaces must be unique."
  }
}
