<!-- tags: ske, workload-identity, iam, kubernetes, oidc, service-account -->

# SKE Workload Identity

## Overview

Demonstrates STACKIT Workload Identity on SKE — pods authenticate to the STACKIT API using short-lived OIDC tokens instead of static service account keys.

The [stackit-pod-identity-webhook](https://github.com/stackitcloud/stackit-pod-identity-webhook) (pre-installed on SKE) intercepts pod creation and injects a projected JWT token and the `STACKIT_SERVICE_ACCOUNT_EMAIL` environment variable. The STACKIT SDK picks these up automatically and exchanges the Kubernetes token for a scoped STACKIT access token.

Reference: [STACKIT Docs — Workload Identity](https://docs.stackit.cloud/products/runtime/kubernetes-engine/how-tos/workload-identity/)

## Prerequisites

- STACKIT provider 0.117.0 or later
- An authenticated `stackit` CLI (`stackit auth login` or `stackit auth activate-service-account`) and `kubectl` for the verify step

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

`terraform.tfvars` needs `stackit_project_id`. Without `kubernetes_version_min`, the provider picks the latest Kubernetes version that SKE supports. Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).

Terraform creates the SKE cluster, the STACKIT service account, and configures the OIDC federation trust automatically. No manual portal steps required.

## Verify

```bash
eval "$(terraform output -raw kubeconfig_command)"
kubectl config use-context "$(terraform output -raw cluster_name)"

# Watch the demo job — it lists the public IP ranges through the STACKIT IaaS API using the injected identity
kubectl logs job/workload-identity-demo -n workload-identity-demo
```

A successful run logs `Authentication successful, API call succeeded`. That line shows that the token exchange worked. The call needs no role on the STACKIT service account.

## Assigning permissions

The created STACKIT service account has no roles by default. Add project-level role assignments in Terraform via `stackit_authorization_project_role_assignment` to match your workload's actual API access requirements. Role assignments belong to the provider experiment `iam`, so add `experiments = ["iam"]` to the `stackit` provider block.
