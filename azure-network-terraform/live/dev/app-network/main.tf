module "network" {
  source = "../../../patterns/vnet"

  workload              = var.workload
  environment           = var.environment
  location              = var.location
  location_short        = var.location_short
  resource_group_name   = var.resource_group_name
  create_resource_group = var.create_resource_group

  address_space = var.address_space
  dns_servers   = var.dns_servers
  route_tables  = var.route_tables
  subnets       = var.subnets

  diagnostics = var.log_analytics_workspace_id == null ? null : {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}
