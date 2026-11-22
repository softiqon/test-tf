output "resource_group_name" {
  value = local.resource_group_name
}

output "resource_group_id" {
  value = local.resource_group_id
}

output "vnet_id" {
  value = module.vnet.id
}

output "vnet_name" {
  value = module.vnet.name
}

output "address_space" {
  value = module.vnet.address_space
}

output "subnets" {
  description = "Subnets keyed by the input key: { id, name, address_prefixes }."
  value = {
    for k, s in module.subnet : k => {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
    }
  }
}

output "subnet_ids" {
  value = { for k, s in module.subnet : k => s.id }
}

output "nsg_ids" {
  value = { for k, n in module.nsg : k => n.id }
}

output "route_table_ids" {
  value = { for k, r in module.route_table : k => r.id }
}
