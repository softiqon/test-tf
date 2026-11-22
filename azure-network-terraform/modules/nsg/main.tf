resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Rules as separate resources so adding/removing one never recreates the NSG.
resource "azurerm_network_security_rule" "this" {
  for_each = var.rules

  name                        = each.key
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
  description                 = each.value.description

  priority  = each.value.priority
  direction = each.value.direction
  access    = each.value.access
  protocol  = each.value.protocol

  # Singular and plural forms are mutually exclusive in the provider.
  source_port_range       = each.value.source_port_ranges == null ? each.value.source_port_range : null
  source_port_ranges      = each.value.source_port_ranges
  destination_port_range  = each.value.destination_port_ranges == null ? each.value.destination_port_range : null
  destination_port_ranges = each.value.destination_port_ranges

  source_address_prefix        = each.value.source_address_prefixes == null ? each.value.source_address_prefix : null
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefixes == null ? each.value.destination_address_prefix : null
  destination_address_prefixes = each.value.destination_address_prefixes
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics == null ? 0 : 1

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_network_security_group.this.id
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
}
