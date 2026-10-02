# Phase 0: Bootstrap

This module provisions a STACKIT project and, in that project, the STACKIT PostgreSQL Flex instance, the `terraform_state` database, and the dedicated `tf_state_user`. Its state is kept locally (or in an independent CI/CD backend) to prevent dependency conflicts.

## Implementation Steps

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `stackit_parent_container_id` and `stackit_org_admin`:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Initialize Terraform with the default local backend:

   ```sh
   terraform init
   ```

3. Provision the project and the PostgreSQL Flex resources:

   ```sh
   terraform apply
   ```

The next phase reads the output `pg_connection_uri` from this directory.
