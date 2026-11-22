# Thin wrapper around the AVM subnet sub-module. One instance = one subnet.
module "this" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.23.0"

  name             = var.name
  parent_id        = var.virtual_network_id
  location         = var.location
  address_prefixes = var.address_prefixes

  network_security_group = var.network_security_group
  route_table            = var.route_table
  nat_gateway            = var.nat_gateway

  service_endpoints = length(var.service_endpoints) > 0 ? var.service_endpoints : null

  delegations = length(var.delegations) > 0 ? [
    for d in var.delegations : {
      name               = d.name
      service_delegation = { name = d.service }
    }
  ] : null

  private_endpoint_network_policies = var.private_endpoint_network_policies
  default_outbound_access_enabled   = var.default_outbound_access_enabled

  enable_telemetry = var.enable_telemetry
}
