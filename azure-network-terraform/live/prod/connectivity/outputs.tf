# Consumed by independently deployed spokes (live/prod/spoke-*) via remote state or tfvars.
output "hub_vnet_id" {
  value = module.hub_spoke.hub.vnet_id
}

output "hub" {
  value = module.hub_spoke.hub
}

output "spokes" {
  value = module.hub_spoke.spokes
}
