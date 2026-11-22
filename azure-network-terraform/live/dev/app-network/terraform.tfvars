subscription_id     = "00000000-0000-0000-0000-000000000000"
environment         = "dev"
workload            = "app"
resource_group_name = "rg-app-network-dev-aue"
address_space       = ["10.100.0.0/16"]

tags = {
  cost_center = "platform"
  owner       = "devops"
}

subnets = {
  app = {
    address_prefixes  = ["10.100.1.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    nsg_rules = {
      allow-https-from-vnet = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    }
  }

  appsvc = {
    address_prefixes = ["10.100.2.0/26"]
    delegations      = [{ name = "webapp", service = "Microsoft.Web/serverFarms" }]
  }

  pe = {
    address_prefixes                  = ["10.100.3.0/24"]
    private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  }
}
