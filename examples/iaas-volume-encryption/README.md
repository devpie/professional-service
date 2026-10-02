<!-- tags: iaas, volume, encryption, kms, block-storage -->

# IaaS Volume Encryption (Terraform)

## Terraform Examples

KMS & IaaS Resources to deploy a encrypted Block Storage Volume

### Usage

The configuration creates a service account with the role `kms.reader`, a KMS keyring with one key, a boot volume encrypted with that key, and a Windows server that boots from the volume.
The server joins a network and a security group that already exist in the project.

Prerequisites:

- Terraform 1.0 or later
- STACKIT provider 0.117.0 or later
- A network and a security group in the project (`stackit network list`, `stackit security-group list`)
- The ID of a Windows Server image (`stackit image list`)

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

| Variable                           | Required | Default  | Meaning                                                        |
| ---------------------------------- | -------- | -------- | -------------------------------------------------------------- |
| `STACKIT_PROJECT_ID`               | yes      | none     | Project that holds all resources                               |
| `image_id`                         | yes      | none     | Windows Server image the encrypted boot volume is created from |
| `network_id`                       | yes      | none     | Existing network the server joins                              |
| `security_group_id`                | yes      | none     | Existing security group of the network interface of the server |
| `administrator_password`           | yes      | none     | Password of the Windows `Administrator` account                |
| `zone`                             | no       | `eu01-3` | Availability zone of the volume and the server                 |
| `stackit_region`                   | no       | `eu01`   | Region of all resources                                        |
| `stackit_service_account_key_path` | no       | unset    | Key file Terraform authenticates with                          |

Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).

Terraform asks for `administrator_password`, or reads it from `TF_VAR_administrator_password`.
`cloud-init.yaml` sets it for the `Administrator` account on the first boot.
Terraform stores the rendered user data, and with it the password, in plain text in the state.
A changed password replaces the server.

### Migrations Steps to move data von non encrypted Volumes to a encrypted Volume

1. Create Backup of non encrypted Volume

There are two options to perform a Backup the first one is to reference a volume directly:

```bash
stackit volume backup create --source-type volume --source-id <volumeId> --name backup01
```

> This does block all operations on the Volume such as extending the Volume until the backup is done.

Another Option is to first create a Snapshot and make a Backup von this Snapshot:

```bash
stackit volume backup create --source-type snapshot --source-id <snapshotId> --name backup01
```

2. Create new encrypted Volume
   Use the provided Terraform to deploy a new encrypted Volume with the same size (or larger) then the original Volume.

3. Create new encrypted Volume from Backup
   Use the Backup as a source for a new encrypted Volume.

```hcl
resource "stackit_volume" "encrypted" {
  project_id        = var.STACKIT_PROJECT_ID
  name              = "encrypted_volume"
  availability_zone = var.zone
  performance_class = "storage_premium_perf6"
  size              = 4
  source = {
    type = "backup"
    id = "<backupId>"
  }
  encryption_parameters = {
    kek_key_id = stackit_kms_key.volume-key.key_id
    kek_key_version = 1
    kek_keyring_id = stackit_kms_keyring.volume.keyring_id
    service_account = "<serviceAccount>@sa.stackit.cloud"
  }
}
```

4. Recreate VM or attach volume to existing VM

```bash
stackit server create --availability-zone eu01-3 --machine-type c2i.2 --boot-volume-source-type volume --boot-volume-source-id <volumeId> --network-id <networkId> -n server1
```
