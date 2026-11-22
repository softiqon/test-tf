# ---------- naming / placement ----------
variable "workload" {
  description = "Short workload name used in resource names, e.g. hub, payments, data."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,24}$", var.workload))
    error_message = "workload must be 2-24 chars: lowercase letters, digits, hyphens."
  }
}

variable "environment" {
  description = "Environment short name, e.g. dev, test, prod."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase alphanumerics."
  }
}

variable "location" {
  description = "Azure region, e.g. australiaeast."
  type        = string
}

variable "location_short" {
  description = "Region abbreviation for names, e.g. aue."
  type        = string
}

variable "name" {
  description = "Override the generated VNet name (vnet-<workload>-<env>-<region>)."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group for the network resources."
  type        = string
}

variable "create_resource_group" {
  description = "Create the resource group (true) or use an existing one (false)."
  type        = bool
  default     = false
}

# ---------- VNet ----------
variable "address_space" {
  description = "VNet address spaces."
  type        = set(string)
}

variable "dns_servers" {
  description = "Custom DNS servers (e.g. hub firewall / DNS resolver IPs)."
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  type    = string
  default = null
}

variable "encryption_enforcement" {
  type    = string
  default = null
}

variable "diagnostics" {
  description = "Log Analytics destination for VNet + NSG diagnostics. null disables."
  type = object({
    log_analytics_workspace_id = string
  })
  default = null
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string)
  })
  default = null
}

# ---------- route tables ----------
variable "route_tables" {
  description = "Route tables keyed by a short name. Subnets reference them via route_table_key."
  type = map(object({
    name                          = optional(string)
    bgp_route_propagation_enabled = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  default = {}
}

# ---------- subnets ----------
variable "subnets" {
  description = "Subnets keyed by a short name. An NSG is created per subnet unless create_nsg = false or the subnet is a platform subnet."
  type = map(object({
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
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in var.subnets : s.route_table_key == null || contains(keys(var.route_tables), coalesce(s.route_table_key, "-"))
    ])
    error_message = "Every subnet route_table_key must match a key in route_tables."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for p in s.address_prefixes : anytrue([
          for a in var.address_space :
          tonumber(split("/", p)[1]) >= tonumber(split("/", a)[1]) &&
          cidrhost("${split("/", p)[0]}/${split("/", a)[1]}", 0) == cidrhost(a, 0)
        ])
      ]
    ]))
    error_message = "Every subnet prefix must sit inside the VNet address_space."
  }
}

# ---------- hub peering (spokes only) ----------
variable "hub_peering" {
  description = "Set to make this VNet a spoke: peers to the hub in both directions."
  type = object({
    hub_vnet_id         = string
    use_remote_gateways = optional(bool, false) # true only if the hub has a VPN/ER gateway
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
