<!-- tags: secrets-manager, vault, secrets, terraform -->

# STACKIT Secrets Manager Vault Provider Integration

## Overview

This guide outlines the process of utilizing the [HashiCorp Vault provider](https://registry.terraform.io/providers/hashicorp/vault)
alongside the STACKIT provider to write secrets in the STACKIT Secrets Manager.

## Prerequisites

- STACKIT provider 0.117.0 or later
- A STACKIT project and a service account key that can create Secrets Manager and Observability instances in it

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

`terraform.tfvars` needs `stackit_project_id`. Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to that entry in its credentials file `$HOME/.stackit/credentials.json` or `STACKIT_CREDENTIALS_PATH` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).

## Resources

- `020-secretsmanager.tf` creates a Secrets Manager instance and a user with write access. The Vault provider logs in to the instance with this user.
- `030-observability.tf` creates an Observability instance and a credential for it. The instance has no default Grafana admin user (`grafana_admin_enabled = false`). Users sign in to Grafana with STACKIT SSO.
- `040-vault-secret.tf` writes the secret `my-secret` into the instance. The secret holds the username and the password of the Observability credential and the static value `other_secret`.

Terraform stores the user password and the Observability credential in plain text in its state.

## Clean up

```bash
terraform destroy
```
