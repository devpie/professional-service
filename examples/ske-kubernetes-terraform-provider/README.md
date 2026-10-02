<!-- tags: ske, kubernetes, terraform, provider, kubeconfig -->

# Terraform SKE Kubernetes Provider Integration

## Overview

Demonstrates how to use the HashiCorp `kubernetes` provider to manage resources inside a SKE cluster.

## Security consideration

This example uses a `stackit_ske_kubeconfig` managed resource to configure the Kubernetes provider. Terraform stores managed resources in state, so the kubeconfig — including client certificates and keys — persists in `terraform.tfstate` for the lifetime of the workspace.

If you are on Terraform >= 1.10, consider the [ske-kubernetes-ephemeral-kubernetes-provider](../ske-kubernetes-ephemeral-kubernetes-provider) example instead. It uses an ephemeral resource to fetch the kubeconfig in memory for the duration of each run and discard it on exit — nothing lands in state. The feature is currently experimental in the STACKIT provider.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

`terraform.tfvars` needs `project_id`. Without `kubernetes_version_min`, the provider creates the cluster on the latest Kubernetes version SKE supports. Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).

The kubeconfig in state expires after one hour. `refresh = true` in `030-ske-cluster.tf` makes the STACKIT provider fetch a new kubeconfig during the refresh step of `terraform plan`, `terraform apply` and `terraform destroy` once less than 30 minutes of its lifetime remain. A run with `-refresh=false` skips that step and uses the kubeconfig from state as it is.
