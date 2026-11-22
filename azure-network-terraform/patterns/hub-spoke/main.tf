# Hub-and-spoke in one state: one hub + N spokes, each spoke peered both ways to the hub.
# Every VNet is built with the same patterns/vnet stamp.
# For spokes in other subscriptions / owned by other teams, deploy patterns/vnet
# from its own root with hub_peering set (see live/prod/spoke-data).

module "hub" {
  source = "../vnet"

  workload              = var.hub.workload
  environment           = var.environment
  location              = var.location
  location_short        = var.location_short
  name                  = var.hub.name
  resource_group_name   = var.hub.resource_group_name
  create_resource_group = var.hub.create_resource_group

  address_space           = var.hub.address_space
  dns_servers             = var.hub.dns_servers
  ddos_protection_plan_id = var.hub.ddos_protection_plan_id
  route_tables            = var.hub.route_tables
  subnets                 = var.hub.subnets

  diagnostics      = var.diagnostics
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

locals {
  force_tunnel = var.firewall_private_ip != null

  # Inject a "to-hub" route table into spokes that route via the hub, and attach it
  # to any subnet that does not already reference its own route table.
  spokes = {
    for k, s in var.spokes : k => merge(s, {
      resource_group_name = coalesce(s.resource_group_name, "rg-${k}-network-${var.environment}-${var.location_short}")
      dns_servers         = s.dns_servers != null ? s.dns_servers : var.hub.dns_servers

      route_tables = merge(s.route_tables, {
        for rk, rv in {
          to-hub = {
            name                          = null
            bgp_route_propagation_enabled = false
            routes = {
              default-to-firewall = {
                address_prefix         = "0.0.0.0/0"
                next_hop_type          = "VirtualAppliance"
                next_hop_in_ip_address = var.firewall_private_ip
              }
            }
          }
        } : rk => rv if local.force_tunnel && s.route_via_hub
      })

      subnets = {
        for sk, sv in s.subnets : sk => merge(sv, {
          route_table_key = (sv.route_table_key != null ? sv.route_table_key
            : (local.force_tunnel && s.route_via_hub ? "to-hub" : null)
          )
        })
      }
    })
  }
}

module "spoke" {
  source   = "../vnet"
  for_each = local.spokes

  workload              = each.key
  environment           = var.environment
  location              = var.location
  location_short        = var.location_short
  name                  = each.value.name
  resource_group_name   = each.value.resource_group_name
  create_resource_group = each.value.create_resource_group

  address_space = each.value.address_space
  dns_servers   = each.value.dns_servers
  route_tables  = each.value.route_tables
  subnets       = each.value.subnets

  hub_peering = {
    hub_vnet_id         = module.hub.vnet_id
    use_remote_gateways = var.hub.has_gateway
  }

  diagnostics      = var.diagnostics
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}
