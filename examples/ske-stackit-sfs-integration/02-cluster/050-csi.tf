# Copyright 2026 Schwarz Digits Cloud GmbH & Co. KG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The cluster ID ternary defers evaluation to the apply phase, so no kubeconfig
# is requested before the cluster exists.
ephemeral "stackit_ske_kubeconfig" "sfs" {
  project_id   = stackit_ske_cluster.sfs.project_id
  cluster_name = stackit_ske_cluster.sfs.id != "" ? stackit_ske_cluster.sfs.name : ""
}

locals {
  # "10.2.1.1:/rp_VKL20Ub/nfs-share" split into the two halves csi-driver-nfs wants.
  nfs_parts  = split(":", local.sfs_mount_path)
  nfs_server = local.nfs_parts[0]
  nfs_share  = try(local.nfs_parts[1], "")
}

# The driver STACKIT documents for File Storage on SKE. The chart brings the
# StorageClass with it.
resource "helm_release" "csi_driver_nfs" {
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  namespace  = "kube-system"
  version    = var.csi_driver_nfs_version

  # Preconditions rather than variable validation, because the value may come
  # from the state of 01-storage.
  lifecycle {
    precondition {
      condition     = length(local.nfs_parts) == 2
      error_message = "The mount path must be <server>:<export path>, for example 10.2.1.1:/rp_VKL20Ub/nfs-share. Got: ${local.sfs_mount_path}"
    }

    # An unfinished pool reports "pending:/rp_XXXXXXX" instead of an address.
    precondition {
      condition     = can(cidrhost("${local.nfs_server}/32", 0))
      error_message = "The part before the colon must be the IPv4 address of the NFS server. Got \"${local.nfs_server}\". A literal \"pending\" means the resource pool in 01-storage has not finished provisioning."
    }
  }

  values = [
    yamlencode({
      storageClasses = [
        {
          name = var.storage_class_name
          parameters = {
            server = local.nfs_server
            share  = local.nfs_share
          }
          reclaimPolicy     = "Retain"
          volumeBindingMode = "Immediate"
          mountOptions      = var.nfs_mount_options
        }
      ]
    })
  ]
}
