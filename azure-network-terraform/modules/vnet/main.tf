# Thin wrapper around the AVM virtual network module.
# Subnets and peerings are intentionally NOT managed here - see modules/subnet and
# modules/peering - so they scale and change independently of the VNet itself.
module "this" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.23.0"

  name          = var.name
  location      = var.location
  parent_id     = var.resource_group_id
  address_space = var.address_space

  dns_servers = length(var.dns_servers) > 0 ? { dns_servers = var.dns_servers } : null

  ddos_protection_plan = var.ddos_protection_plan_id == null ? null : {
    id     = var.ddos_protection_plan_id
    enable = true
  }

  encryption = var.encryption_enforcement == null ? null : {
    enabled     = true
    enforcement = var.encryption_enforcement
  }

  # Keys are static so for_each inside AVM never sees unknown keys at plan time.
  diagnostic_settings = {
    for k, v in { default = var.diagnostics } : k => {
      name                  = "diag-${var.name}"
      workspace_resource_id = v.log_analytics_workspace_id
    } if v != null
  }

  enable_vm_protection = var.enable_vm_protection
  lock                 = var.lock
  tags                 = var.tags
  enable_telemetry     = var.enable_telemetry

  subnets = {}
}
