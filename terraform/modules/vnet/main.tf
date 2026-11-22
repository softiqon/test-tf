module "this" {
    source = "Azure/avm-res-network-virtualnetwork/azurerm"
    version = "0.23.0"

    name          = var.name
    location      = var.location
    parent_id     = var.resource_group_id
    address_space = var.address_space

    tags = var.tags
    lock = var.lock

    subnets = {}


}