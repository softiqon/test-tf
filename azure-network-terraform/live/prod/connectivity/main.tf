module "hub_spoke" {
  source = "../../../patterns/hub-spoke"

  environment         = var.environment
  location            = var.location
  location_short      = var.location_short
  firewall_private_ip = var.firewall_private_ip

  hub    = var.hub
  spokes = var.spokes

  diagnostics = var.log_analytics_workspace_id == null ? null : {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}
