# A spoke deployed on its own (different subscription, team or lifecycle) that
# peers to the shared hub. Copy this folder per spoke, or drive it from a
# subscription-vending pipeline.
#
# Alternative to passing hub_vnet_id in tfvars:
# data "terraform_remote_state" "connectivity" {
#   backend = "azurerm"
#   config  = { ..., key = "network/prod-connectivity.tfstate", use_azuread_auth = true }
# }
# hub_vnet_id = data.terraform_remote_state.connectivity.outputs.hub_vnet_id

module "network" {
  source = "../../../patterns/vnet"

  workload              = var.workload
  environment           = var.environment
  location              = var.location
  location_short        = var.location_short
  resource_group_name   = var.resource_group_name
  create_resource_group = true

  address_space = var.address_space
  dns_servers   = var.dns_servers
  route_tables  = var.route_tables
  subnets       = var.subnets

  # The deploying identity needs Network Contributor on the hub VNet
  # to create the reverse (hub -> spoke) peering.
  hub_peering = {
    hub_vnet_id         = var.hub_vnet_id
    use_remote_gateways = var.use_hub_gateway
  }

  diagnostics = var.log_analytics_workspace_id == null ? null : {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}
