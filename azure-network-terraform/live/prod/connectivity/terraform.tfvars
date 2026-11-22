subscription_id = "11111111-1111-1111-1111-111111111111" # connectivity subscription
environment     = "prod"

# Azure Firewall takes the first usable IP (.4) of AzureFirewallSubnet.
firewall_private_ip = "10.0.0.68"

tags = {
  cost_center = "platform"
  owner       = "devops"
}

hub = {
  resource_group_name = "rg-hub-network-prod-aue"
  address_space       = ["10.0.0.0/22"]
  dns_servers         = ["10.0.1.68"] # Private DNS Resolver inbound endpoint (deployed separately)
  has_gateway         = false         # set true once the VPN/ER gateway exists

  route_tables = {
    gateway = {
      # On-prem -> spokes must traverse the firewall.
      routes = {
        to-spoke-payments = { address_prefix = "10.10.0.0/16", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.0.68" }
        to-spoke-aks      = { address_prefix = "10.20.0.0/16", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.0.68" }
        to-spoke-data     = { address_prefix = "10.30.0.0/16", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.0.68" }
      }
    }
  }

  subnets = {
    gateway = {
      name             = "GatewaySubnet"
      address_prefixes = ["10.0.0.0/27"]
      route_table_key  = "gateway"
    }
    firewall = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.0.64/26"]
    }
    firewall-mgmt = {
      name             = "AzureFirewallManagementSubnet"
      address_prefixes = ["10.0.0.128/26"]
    }
    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.1.0/26"]
      create_nsg       = false # Bastion NSG needs a fixed rule set; manage it explicitly if required
    }
    dns-inbound = {
      address_prefixes = ["10.0.1.64/28"]
      delegations      = [{ name = "resolver", service = "Microsoft.Network/dnsResolvers" }]
    }
    dns-outbound = {
      address_prefixes = ["10.0.1.80/28"]
      delegations      = [{ name = "resolver", service = "Microsoft.Network/dnsResolvers" }]
    }
    mgmt = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

# Spokes owned by the platform team, same subscription/state.
# Add a spoke = add a map entry. Spokes in other subscriptions -> live/prod/spoke-*.
spokes = {
  payments = {
    address_space = ["10.10.0.0/16"]
    subnets = {
      app = {
        address_prefixes = ["10.10.1.0/24"]
        nsg_rules = {
          allow-https-from-hub = {
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            destination_port_range     = "443"
            source_address_prefix      = "10.0.0.0/22"
            destination_address_prefix = "*"
          }
        }
      }
      pe = {
        address_prefixes                  = ["10.10.2.0/24"]
        private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
      }
    }
  }

  aks = {
    address_space = ["10.20.0.0/16"]
    subnets = {
      # AKS cluster must use outbound_type = "userDefinedRouting" with the firewall UDR.
      nodes = {
        address_prefixes = ["10.20.0.0/22"]
      }
      ingress = {
        address_prefixes = ["10.20.4.0/24"]
      }
    }
  }
}
