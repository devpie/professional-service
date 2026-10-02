# Phase 1: Example Infrastructure

This module contains the core infrastructure configuration. It uses the `pg` backend to store state and enforce state locks via the STACKIT PostgreSQL Flex database provisioned in Phase 0.

## Implementation Steps

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `stackit_parent_container_id` and `stackit_org_admin`:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Write `backend.conf` from the output of the bootstrap module. `backend.conf.example` shows the format.

   ```sh
   printf 'conn_str = "%s"\n' "$(terraform -chdir=../00-bootstrap output -raw pg_connection_uri)" > backend.conf
   ```

3. Initialize Terraform and bind it to the remote PostgreSQL backend:

   ```sh
   terraform init -backend-config=backend.conf
   ```

4. Run the lock validation script:

   ```sh
   ./scripts/validate_lock.sh
   ```

   The script runs `terraform apply -auto-approve` in the background and `terraform plan` at the same time. Terraform takes the state lock before it does anything else, so the backend rejects the command that comes second. The apply creates the project from `030-project.tf` when it is the one that holds the lock. When the plan holds the lock, the backend rejects the apply. Run `terraform apply` afterwards to create the project.

## Log Output

This log shows a run in which the backend rejects the plan:

```sh
➜  01-example-project ~ ./scripts/validate_lock.sh
[INFO] Starting 'terraform apply' in the background...
[INFO] Running 'terraform plan' at the same time...
[INFO] ------------------------------------------------------------------

Error: Error acquiring the state lock

Error message: Already locked for workspace creation: default
Lock Info:
  ID:        XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXXXX
  Path:
  Operation: OperationTypePlan
  Who:       XXXX
  Version:   1.14.9
  Created:   2026-06-25 16:21:59.636986 +0000 UTC
  Info:


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.

[INFO] ------------------------------------------------------------------
[INFO] Waiting for the background 'terraform apply' to finish...
[SUCCESS] 'terraform plan' was rejected while 'terraform apply' held the state lock.
```

On the first run the backend reports `Already locked for workspace creation: default`, because no state exists yet. On later runs it reports `Workspace is already locked: default`.
