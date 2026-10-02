<!-- tags: ske, external-secrets, kubernetes, secrets-manager, secrets -->

# Terraform SKE External-Secrets/STACKIT Secret-Manager Sync

## Overview

This repository demonstrates how to synchronize STACKIT Secrets Manager secrets with Kubernetes secrets using External Secrets.

## Usage

The `ClusterSecretStore` and the `ExternalSecret` are custom resources of the External Secrets Operator. Terraform needs a working connection to the cluster and the installed CRDs already while it plans them. On an empty state, apply the cluster and the operator chart first. A `depends_on` does not help here: it orders the apply, but Terraform plans all resources before it applies any.

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -target=helm_release.external_secrets_operator_chart
terraform apply
```

The first apply creates the SKE cluster and installs the operator chart. The second apply creates everything else: the Secrets Manager instance and user, the random secret in it, and the two custom resources.

`terraform.tfvars` needs `stackit_project_id`. Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)). Without `kubernetes_version_min`, SKE creates the cluster on the latest Kubernetes version it supports.
