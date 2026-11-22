module "rg" {
  source   = "./modules/resource_group"
  name     = "rg-gdt-bidding-dev-aue"
  location = "australiaeast"
}

module "vnet" {
  source        = "./modules/vnet"
  name          = "vnet-gdt-bidding-dev-aue"
  location      = "australiaeast"
  resource_group_id = module.rg.id
  address_space = ["10.0.0.0/16"]
  lock = {
    kind = CanNotDelete
    name = sample
    }
}