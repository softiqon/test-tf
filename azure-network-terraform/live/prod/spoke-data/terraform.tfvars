subscription_id     = "22222222-2222-2222-2222-222222222222" # data landing-zone subscription
environment         = "prod"
workload            = "data"
resource_group_name = "rg-data-network-prod-aue"
address_space       = ["10.30.0.0/16"]
dns_servers         = ["10.0.1.68"]

hub_vnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-hub-network-prod-aue/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-aue"

route_tables = {
  to-hub = {
    bgp_route_propagation_enabled = false
    routes = {
      default-to-firewall = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.0.68"
      }
    }
  }
}

subnets = {
  databricks-public = {
    address_prefixes = ["10.30.0.0/24"]
    route_table_key  = "to-hub"
    delegations      = [{ name = "databricks", service = "Microsoft.Databricks/workspaces" }]
  }
  databricks-private = {
    address_prefixes = ["10.30.1.0/24"]
    route_table_key  = "to-hub"
    delegations      = [{ name = "databricks", service = "Microsoft.Databricks/workspaces" }]
  }
  pe = {
    address_prefixes                  = ["10.30.2.0/24"]
    route_table_key                   = "to-hub"
    private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  }
}
