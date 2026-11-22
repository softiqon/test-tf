output "id" {
  description = "VNet resource ID."
  value       = module.this.resource_id
}

output "name" {
  description = "VNet name."
  value       = var.name
}

output "address_space" {
  description = "VNet address space."
  value       = var.address_space
}
