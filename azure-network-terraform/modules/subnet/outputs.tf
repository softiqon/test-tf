output "id" {
  description = "Subnet resource ID."
  value       = module.this.resource_id
}

output "name" {
  description = "Subnet name."
  value       = var.name
}

output "address_prefixes" {
  description = "Subnet CIDRs."
  value       = var.address_prefixes
}
