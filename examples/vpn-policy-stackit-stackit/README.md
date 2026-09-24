<!-- tags: vpn, networking, ipsec, site-to-site, policy-based -->

# STACKIT-to-STACKIT Policy-Based VPN Gateway

This example establishes a policy-based IPsec VPN connection between two separate STACKIT Network Areas (SNAs).

Unlike BGP-based or route-based VPNs, a policy-based VPN uses **traffic selectors** (`local_subnets` / `remote_subnets`) to decide which traffic enters the tunnel. There is no dynamic routing protocol — the gateway creates a dedicated IPsec Security Association (SA) for each subnet pair defined in the policy.

## When to use this example

**Use policy-based when:**

- The remote peer **only supports policy-based VPN** (older firewalls, some managed or legacy appliances that have no VTI support)
- The set of subnets is **small and stable** — each subnet pair requires its own SA, so a long or frequently changing list becomes hard to maintain
- You need the traffic selector **enforced at the IPsec engine level**, not just by routing

**Do not use policy-based when:**

- The subnet list **changes frequently** — use [route-based](../vpn-route-stackit-stackit/) (static routes) or [BGP](../vpn-bgp-stackit-stackit/) (dynamic)
- The remote peer **supports BGP** — use [BGP route-based](../vpn-bgp-stackit-stackit/) for automatic route propagation and faster failover

## Choosing the right VPN type

|                             | Policy-based              | Route-based                 | BGP route-based                   |
| --------------------------- | ------------------------- | --------------------------- | --------------------------------- |
| `routing_type`              | `POLICY_BASED`            | `ROUTE_BASED`               | `BGP_ROUTE_BASED`                 |
| Routes defined by           | Traffic selectors         | `static_routes`             | BGP advertisements                |
| Remote subnet changes       | Terraform change required | Terraform change required   | Automatic                         |
| BGP required on remote peer | No                        | No                          | Yes                               |
| Typical use case            | Legacy appliances         | On-prem appliances with VTI | Cloud providers, modern firewalls |

## Architecture

|                | SNA 01          | SNA 02          |
| -------------- | --------------- | --------------- |
| SNA range      | `10.10.0.0/16`  | `10.11.0.0/16`  |
| Machine subnet | `10.10.10.0/24` | `10.11.11.0/24` |
| AZ (machine)   | `eu01-1`        | `eu01-2`        |

Each gateway exposes two public tunnel endpoints (`tunnel1`, `tunnel2`) for redundancy. Both tunnels carry the same traffic selectors, so either can handle the traffic if one endpoint becomes unavailable.

## Key differences from the BGP example

|                                               | Policy-based               | BGP-based                          |
| --------------------------------------------- | -------------------------- | ---------------------------------- |
| `routing_type`                                | `POLICY_BASED`             | `BGP_ROUTE_BASED`                  |
| Route propagation                             | Static (traffic selectors) | Dynamic (BGP)                      |
| Gateway `bgp` block                           | Not present                | Required                           |
| Tunnel `bgp` / `peering` blocks               | Not present                | Required                           |
| Connection `local_subnets` / `remote_subnets` | **Mandatory**              | Optional (defaults to `0.0.0.0/0`) |

## How to Test the Connection

Once the deployment is complete, verify the VPN tunnel using the provisioned debug machines:

1. **SSH** into the first debug machine using its public IP (`vpn01_public_ip`).
2. **Ping** the private IP of the second debug machine (`vpn02_private_ip`) across the tunnel.

```bash
# SSH into the first debug machine
ssh debug@<vpn01_public_ip>
# password: debug123

# Ping across the tunnel
ping <vpn02_private_ip>
```
