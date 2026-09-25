# Stage 1: File Storage

Creates the address space, the project and the SFS share. Run before
[`../02-cluster`](../02-cluster).

| Resource                                                 | Note                                                                               |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `stackit_network_area` and `stackit_network_area_region` | Organization-level. The `preview/routingtables` label is required for SFS.         |
| `stackit_resourcemanager_project`                        | Directly under the organization. SKE rejects a cluster in a folder-nested project. |
| `stackit_sfs_resource_pool`                              | 500 GB minimum, 512 GB by default.                                                 |
| `stackit_sfs_export_policy`                              | Who may mount the share, and with which rights.                                    |
| `stackit_sfs_share`                                      | What the cluster mounts.                                                           |

File Storage itself does not care where the project sits. The SKE cluster in stage 2
does, which is why this one goes under the organization.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## If the resource pool times out

The provider has no state attribute, so ask the API:

```bash
stackit beta sfs resource-pool describe <pool id> --project-id <project id> --region <region> -o json
```

`created` means it finished late. The provider writes the ID to state before it starts
polling, so the pool is already there, only tainted. Clear the taint instead of letting
Terraform replace it:

```bash
terraform untaint stackit_sfs_resource_pool.sfs
```

`pending` or `creating`, or a `mountPath` of `pending:/rp_XXXXXXX`, means the pool never
got a network endpoint. Waiting longer will not help; contact STACKIT support.

`terraform destroy` frees the network area only once no project references it.
