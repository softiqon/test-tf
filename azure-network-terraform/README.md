# Azure network IaC (AVM-based)

Layered Terraform for Azure networking, built on the Azure Verified Modules (AVM)
`avm-res-network-virtualnetwork` module v0.23.0 and its `subnet` and `peering` sub-modules.

```
modules/          Building blocks: one resource concern each, thin AVM/azurerm wrappers
  vnet/           VNet only (address space, DNS, DDoS, encryption, diagnostics, lock)
  subnet/         One subnet (NSG / UDR / NAT GW association, delegations, endpoints)
  nsg/            NSG + rules as separate resources + diagnostics
  route-table/    Route table + routes
  peering/        Bidirectional VNet peering (cross-subscription capable)
patterns/         Opinionated compositions = what roots call
  vnet/           VNet "stamp": RG + VNet + NSG-per-subnet + route tables + subnets (+ hub peering)
  hub-spoke/      Hub + N spokes, all built from patterns/vnet, auto-peered, optional forced tunnelling
live/             Deployable roots: one state file per root, config only in tfvars
  dev/app-network      Standalone VNet (no hub)
  prod/connectivity    Hub + platform-owned spokes in one state
  prod/spoke-data      Vended spoke: own subscription/state, peers to the prod hub
pipelines/        Azure Pipelines: fmt/validate/tflint/checkov -> plan -> approved apply (OIDC)
```

## Design decisions

- **Subnets are separate from the VNet.** `modules/vnet` always passes `subnets = {}`, and each subnet is its own
  `modules/subnet` instance (`for_each`). Adding or removing a subnet never touches the VNet or the other subnets.
  Never manage the same VNet's subnets both inline and separately.
- **There is one stamp for every VNet.** Standalone VNets, hubs and spokes all use `patterns/vnet`, so naming, tagging,
  NSG-per-subnet, diagnostics and secure defaults are identical everywhere.
- **Two hub-spoke deployment models:**
  - *Single state* (`patterns/hub-spoke`). Fine for a handful of spokes owned by the platform team. Add a spoke by adding a
    map entry to `spokes`.
  - *Spoke vending* (`patterns/vnet` with `hub_peering` set, one root per spoke). Use it for spokes in other subscriptions,
    for many spokes, or for spokes owned by app teams. It keeps blast radius and state size small, and each spoke has its
    own lifecycle.
- **Scaling is driven by `for_each` over maps with stable keys.** Keys are fixed in tfvars, so adding an item never
  re-indexes or recreates others (unlike `count`).
- **Values that are only known after apply never feed `count`, `for_each` or map keys.** Optional associations are passed
  as `{ id = ... }` objects or null, so plans work even when the NSG or route table is created in the same apply.
- **Secure defaults:**
  - `default_outbound_access_enabled = false`, so there is no implicit internet egress. Use a NAT gateway or the firewall.
  - Every subnet gets an NSG automatically, except GatewaySubnet, AzureFirewallSubnet, AzureFirewallManagementSubnet and
    RouteServerSubnet, which can't have one.
  - Spokes get a `0.0.0.0/0` route to the hub firewall when `firewall_private_ip` is set (opt out with
    `route_via_hub = false`).
- **Versions are pinned.** AVM modules are pinned exactly, because they are pre-1.0 and inputs change between minors.
  Providers use `~>` ranges in roots, and `.terraform.lock.hcl` is committed per root.
- **Validation happens at the pattern layer:** CIDRs, subnets inside the address space, route-table key references,
  unique spoke ranges, NSG priority uniqueness and next-hop rules. This needs Terraform >= 1.9 for cross-variable
  validation.

## Naming (CAF-style)

| Resource | Pattern | Example |
|---|---|---|
| VNet | `vnet-<workload>-<env>-<region>` | `vnet-hub-prod-aue` |
| Subnet | `snet-<key>` (or exact name for platform subnets) | `snet-app`, `GatewaySubnet` |
| NSG | `nsg-<subnet>-<workload>-<env>-<region>` | `nsg-snet-app-payments-prod-aue` |
| Route table | `rt-<key>-<workload>-<env>-<region>` | `rt-to-hub-aks-prod-aue` |
| Spoke RG | `rg-<spoke>-network-<env>-<region>` | `rg-payments-network-prod-aue` |
| Peering | `peer-<vnet>-to-hub` / `peer-hub-to-<vnet>` | |

## Usage

```bash
cd live/prod/connectivity
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

Run `terraform fmt -recursive` after edits.

### Add a spoke (single-state model)

Add an entry to `spokes` in `live/prod/connectivity/terraform.tfvars`:

```hcl
spokes = {
  # ...existing...
  crm = {
    address_space = ["10.40.0.0/16"]
    subnets = {
      app = { address_prefixes = ["10.40.1.0/24"] }
      pe  = { address_prefixes = ["10.40.2.0/24"], private_endpoint_network_policies = "NetworkSecurityGroupEnabled" }
    }
  }
}
```

Also add a `to-spoke-crm` route to the hub `gateway` route table, so on-prem traffic to the new spoke goes through the
firewall.

### Add a spoke (vending model)

1. Copy `live/prod/spoke-data` to `live/prod/spoke-<name>`.
2. Edit `backend.hcl`: set a new state `key`.
3. Edit `terraform.tfvars`: set the subscription, address space and subnets.
4. Add a stage to the pipeline with `applyDependsOn: [apply_prod_connectivity]`.

The pipeline identity needs **Network Contributor on the hub VNet** to create the reverse peering.

## Ordering and gotchas

- Set `hub.has_gateway = true` only after the VPN or ExpressRoute gateway exists. Otherwise `use_remote_gateways`
  fails on the spoke peerings.
- AKS behind the firewall UDR needs `outbound_type = "userDefinedRouting"` and the AKS egress firewall rules.
- Azure Bastion: `create_nsg = false` by default here. If policy requires an NSG, supply the full Bastion rule set via
  `nsg_rules`.
- When you add address space to a peered VNet, the peering must re-sync. The AVM peering module supports
  `sync_remote_address_space_enabled` and triggers if you need that automated.
- For overlapping-range protection across many teams, use Azure Virtual Network Manager IPAM (`ipam_pools` in AVM)
  instead of hand-managed CIDRs.

## Not included (deploy separately, wire in by ID)

Azure Firewall and its policy, VPN/ER gateway, Bastion host, Private DNS Resolver and private DNS zones, NAT
gateways, DDoS plan, Log Analytics workspace, NSG flow logs (VNet flow logs), and Azure Policy.
