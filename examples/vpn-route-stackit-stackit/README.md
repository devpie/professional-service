<!-- tags: vpn, networking, ipsec, site-to-site, route-based, sna -->

# STACKIT-to-STACKIT Route-Based VPN Gateway

This example establishes a route-based IPsec VPN connection between two separate STACKIT Network Areas (SNAs).

A route-based VPN steers traffic into the tunnel via the routing table using a virtual tunnel interface (VTI). Routes are defined with `static_routes` on the connection — no traffic selectors, no BGP.

## When to use this example

**Use route-based when:**

- The subnet list is **larger or changes over time** — a single `static_routes` list is easier to maintain than matched `local_subnets`/`remote_subnets` pairs on both ends
- You want a **migration path to BGP** — switching from `ROUTE_BASED` to `BGP_ROUTE_BASED` only adds a `bgp` block; the rest stays the same
- The remote peer **does not support BGP** but does support VTI/route-based mode

**Do not use route-based when:**

- The remote peer **only supports policy-based VPN** (no VTI) — use [policy-based](../vpn-policy-stackit-stackit/) instead
- The remote peer **supports BGP** — use [BGP route-based](../vpn-bgp-stackit-stackit/) for automatic route propagation and faster failover

## Choosing the right VPN type

|                             | Policy-based              | Route-based                 | BGP route-based                   |
| --------------------------- | ------------------------- | --------------------------- | --------------------------------- |
| `routing_type`              | `POLICY_BASED`            | `ROUTE_BASED`               | `BGP_ROUTE_BASED`                 |
| Routes defined by           | Traffic selectors         | `static_routes`             | BGP advertisements                |
| Remote subnet changes       | Terraform change required | Terraform change required   | Automatic                         |
| BGP required on remote peer | No                        | No                          | Yes                               |
| Typical use case            | Legacy appliances         | On-prem appliances with VTI | Cloud providers, modern firewalls |

## How static_routes works

`static_routes` on a connection tells the STACKIT gateway which remote CIDRs are reachable through that tunnel. Traffic destined for those CIDRs is sent into the VTI; everything else is not. Each side advertises its own network to the other:

```
GW1 connection → static_routes = ["10.11.0.0/16"]   # GW2's network
GW2 connection → static_routes = ["10.10.0.0/16"]   # GW1's network
```

## How to Test the Connection

Once the deployment is complete, verify the VPN tunnel using the provisioned debug machines:

```bash
# SSH into the first debug machine
ssh debug@<vpn01_public_ip>
# password: debug123

# Ping across the tunnel
ping <vpn02_private_ip>
```
