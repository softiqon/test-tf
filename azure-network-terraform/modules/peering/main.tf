# Thin wrapper around the AVM peering sub-module. Creates local -> remote and,
# optionally, the reverse remote -> local peering in a single unit.
# azapi addresses resources by full ID, so the remote VNet may live in another
# subscription as long as the deploying identity has rights on it.
module "this" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.23.0"

  name                      = var.name
  parent_id                 = var.local_virtual_network_id
  remote_virtual_network_id = var.remote_virtual_network_id
  location                  = var.location

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways

  create_reverse_peering               = var.create_reverse_peering
  reverse_name                         = var.reverse_name
  reverse_allow_virtual_network_access = true
  reverse_allow_forwarded_traffic      = var.reverse_allow_forwarded_traffic
  reverse_allow_gateway_transit        = var.reverse_allow_gateway_transit
  reverse_use_remote_gateways          = var.reverse_use_remote_gateways

  enable_telemetry = var.enable_telemetry
}
