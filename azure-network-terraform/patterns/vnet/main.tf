# VNet "stamp": RG (optional) + VNet + NSGs + route tables + subnets + optional hub peering.
# Used directly for standalone VNets, and composed by patterns/hub-spoke for the hub and every spoke.

data "azurerm_client_config" "current" {}

locals {
  name_suffix = "${var.workload}-${var.environment}-${var.location_short}"
  vnet_name   = coalesce(var.name, "vnet-${local.name_suffix}")

  tags = merge({
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
  }, var.tags)

  # Platform subnets that must not have an NSG.
  nsg_exempt_names = ["GatewaySubnet", "AzureFirewallSubnet", "AzureFirewallManagementSubnet", "RouteServerSubnet"]

  subnets = {
    for k, s in var.subnets : k => merge(s, { name = coalesce(s.name, "snet-${k}") })
  }

  nsg_subnets = {
    for k, s in local.subnets : k => s if s.create_nsg && !contains(local.nsg_exempt_names, s.name)
  }
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

locals {
  # Referencing the resource (when created) gives Terraform the dependency edge.
  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : var.resource_group_name
  resource_group_id = (var.create_resource_group
    ? azurerm_resource_group.this[0].id
    : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  )
}

module "vnet" {
  source = "../../modules/vnet"

  name                    = local.vnet_name
  location                = var.location
  resource_group_id       = local.resource_group_id
  address_space           = var.address_space
  dns_servers             = var.dns_servers
  ddos_protection_plan_id = var.ddos_protection_plan_id
  encryption_enforcement  = var.encryption_enforcement
  diagnostics             = var.diagnostics
  lock                    = var.lock
  tags                    = local.tags
  enable_telemetry        = var.enable_telemetry
}

module "route_table" {
  source   = "../../modules/route-table"
  for_each = var.route_tables

  name                          = coalesce(each.value.name, "rt-${each.key}-${local.name_suffix}")
  location                      = var.location
  resource_group_name           = local.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  tags                          = local.tags
}

module "nsg" {
  source   = "../../modules/nsg"
  for_each = local.nsg_subnets

  name                = "nsg-${each.value.name}-${local.name_suffix}"
  location            = var.location
  resource_group_name = local.resource_group_name
  rules               = each.value.nsg_rules
  diagnostics         = var.diagnostics
  tags                = local.tags
}

module "subnet" {
  source   = "../../modules/subnet"
  for_each = local.subnets

  name               = each.value.name
  virtual_network_id = module.vnet.id
  location           = var.location
  address_prefixes   = each.value.address_prefixes

  network_security_group = contains(keys(local.nsg_subnets), each.key) ? { id = module.nsg[each.key].id } : null
  route_table            = each.value.route_table_key == null ? null : { id = module.route_table[each.value.route_table_key].id }
  nat_gateway            = each.value.nat_gateway_id == null ? null : { id = each.value.nat_gateway_id }

  service_endpoints                 = each.value.service_endpoints
  delegations                       = each.value.delegations
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
  default_outbound_access_enabled   = each.value.default_outbound_access_enabled
  enable_telemetry                  = var.enable_telemetry
}

# Spoke -> hub (+ reverse hub -> spoke). Only when this VNet is a spoke.
module "hub_peering" {
  source = "../../modules/peering"
  count  = var.hub_peering == null ? 0 : 1

  name                      = "peer-${local.vnet_name}-to-hub"
  local_virtual_network_id  = module.vnet.id
  remote_virtual_network_id = var.hub_peering.hub_vnet_id
  location                  = var.location

  allow_forwarded_traffic = true
  use_remote_gateways     = var.hub_peering.use_remote_gateways

  create_reverse_peering          = true
  reverse_name                    = "peer-hub-to-${local.vnet_name}"
  reverse_allow_forwarded_traffic = true
  reverse_allow_gateway_transit   = var.hub_peering.use_remote_gateways

  enable_telemetry = var.enable_telemetry

  # Avoid AnotherOperationInProgress on the VNet while subnets are still being created.
  depends_on = [module.subnet]
}
