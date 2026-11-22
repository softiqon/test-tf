module "this" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  name     = var.name
  location = var.location

  tags = var.tags
  lock = var.lock
}