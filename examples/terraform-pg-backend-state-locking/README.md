<!-- tags: terraform, postgresql, state, backend, remote-state, locking -->

# STACKIT Terraform PostgreSQL Backend with State Locking

This repository demonstrates how to configure STACKIT PostgreSQL Flex as a Terraform backend to enable remote state storage and native state locking.

To resolve the circular dependency of provisioning a state backend using Terraform, the deployment is split into two isolated stages:

1. **`00-bootstrap/`**: Provisions the backend infrastructure (PostgreSQL Flex instance, database and service user).
2. **`01-example-project/`**: Represents the primary infrastructure, utilizing the provisioned PostgreSQL database as its remote backend.

---

**⚠️ Security Notice:** The PostgreSQL Flex instance in `00-bootstrap/` is configured with an open ACL (`0.0.0.0/0`) for development convenience. Before deploying to production, restrict the ACL to your specific egress IP ranges to prevent the database from being accessible via the public internet.

> [!WARNING]
> Four places hold the password of `tf_state_user` in plain text:
>
> - the local state of `00-bootstrap/`
> - the output `pg_connection_uri`, even though `040-output.tf` marks it `sensitive`
> - `01-example-project/backend.conf`
> - `01-example-project/.terraform/terraform.tfstate` after `terraform init -backend-config`, because Terraform stores the backend configuration there
>
> Anyone who can read one of them can read the password. The `.gitignore` of this repository covers `terraform.tfstate`, `terraform.tfstate.backup`, `backend.conf` and the `.terraform/` directory. This setup is only an example and should not be used this way in production.

## Prerequisites

- Terraform.
- STACKIT provider 0.117.0 or later.
- A service account key for Terraform, see `stackit_service_account_key_path` in `000-variables.tf` of both stages. The service account holds a role on the parent container that includes `resource-manager.project.create` and applies to the new projects, for example `owner`. The two stages create one project each.
- The ID of the parent container. `stackit_parent_container_id` takes an organization or a folder.

## Clean up

Destroy the stages in reverse order. The database of the bootstrap stage holds the state of the example project, so `terraform destroy` in `01-example-project/` needs that database.

```sh
terraform -chdir=01-example-project destroy
terraform -chdir=00-bootstrap destroy
```
