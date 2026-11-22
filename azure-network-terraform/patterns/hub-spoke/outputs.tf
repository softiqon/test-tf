output "hub" {
  description = "Hub VNet details."
  value = {
    vnet_id             = module.hub.vnet_id
    vnet_name           = module.hub.vnet_name
    resource_group_name = module.hub.resource_group_name
    subnets             = module.hub.subnets
  }
}

output "spokes" {
  description = "Spoke VNet details keyed by spoke name."
  value = {
    for k, s in module.spoke : k => {
      vnet_id             = s.vnet_id
      vnet_name           = s.vnet_name
      resource_group_name = s.resource_group_name
      subnets             = s.subnets
    }
  }
}
