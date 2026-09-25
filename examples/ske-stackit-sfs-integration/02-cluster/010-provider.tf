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

terraform {
  # Ephemeral resources (see 050-csi.tf) require Terraform 1.10 or later.
  required_version = ">= 1.10.0"
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.116.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }
  }
}

provider "stackit" {
  default_region           = var.stackit_region
  service_account_key_path = var.stackit_service_account_key_path

  # The ephemeral kubeconfig in 050-csi.tf belongs to the ske experiment.
  experiments = ["ske"]
}

# Fed from an ephemeral resource, so no admin credential lands in the state
# file. The cost is in the README.
provider "helm" {
  kubernetes = {
    host                   = yamldecode(ephemeral.stackit_ske_kubeconfig.sfs.kube_config).clusters.0.cluster.server
    client_certificate     = base64decode(yamldecode(ephemeral.stackit_ske_kubeconfig.sfs.kube_config).users.0.user.client-certificate-data)
    client_key             = base64decode(yamldecode(ephemeral.stackit_ske_kubeconfig.sfs.kube_config).users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(ephemeral.stackit_ske_kubeconfig.sfs.kube_config).clusters.0.cluster.certificate-authority-data)
  }
}
