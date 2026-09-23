# Stage 2: Cluster and CSI driver

Creates the cluster and gives it the SFS share as a `ReadWriteMany` StorageClass. Run
[`../01-storage`](../01-storage) first.

| Resource                           | Note                                                                          |
| ---------------------------------- | ----------------------------------------------------------------------------- |
| `stackit_network`                  | Prefix out of the network area range, which is how the nodes reach the share. |
| `stackit_ske_cluster`              | Node pool starts at two nodes, see Verify.                                    |
| `ephemeral.stackit_ske_kubeconfig` | Fetched per run, never written to state.                                      |
| `helm_release.csi_driver_nfs`      | The driver STACKIT prefers for SFS on SKE, plus the StorageClass.             |

## Usage

```bash
terraform init
terraform apply
```

Project and mount path come from `../01-storage/terraform.tfstate`. Set
`stackit_project_id` and `sfs_mount_path` yourself to skip that read.

## Verify

```bash
eval "$(terraform output -raw kubeconfig_command)"
kubectl config use-context "$(terraform output -raw ske_cluster_name)"
kubectl apply -f example-rwx-deployment.yaml
kubectl get pods -l app=rwx-test -o wide
kubectl exec deploy/rwx-test -c rwx-test -- head -20 /data/index.html
```

Four pods `Running` on two or more distinct nodes, all appending to the same file. That
is why the node pool starts at two nodes: on one node the demo would pass on
`ReadWriteOnce` too.

It does not prove that Kubernetes enforces `ReadWriteMany`. `nfs.csi.k8s.io` sets
`attachRequired: false`, so `ReadWriteOnce` would run just the same.

`PersistentVolumeClaim.yaml` is a smaller claim for checking that the StorageClass binds.

## Clean up

```bash
kubectl delete -f example-rwx-deployment.yaml
terraform destroy
```

The workload comes from `kubectl`, so Terraform does not know about its `LoadBalancer`
service and will not release its address. `reclaimPolicy: Retain` keeps volumes and data
after a claim is deleted.

## The ephemeral kubeconfig

It keeps admin credentials out of the state file, and it makes itself a dependency of
every operation here, `terraform import` included. While the cluster does not exist,
import fails in this stage. Stage 1 is free of it.
