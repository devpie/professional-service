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

# --  variables
variable "organization_id" {
  type        = string
  description = "STACKIT organization ID (required)"
  default     = "" # set your organization ID here

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Set organization_id in 020-variables.tf to your STACKIT organization ID (UUID)."
  }
}

variable "owner_email" {
  type        = string
  description = "Owner e-mail of the STACKIT projects (required)"
  default     = "" # set your e-mail here

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner_email))
    error_message = "Set owner_email in 020-variables.tf to the e-mail address of the project owner."
  }
}

variable "projects" {
  type = map(object({
    name        = string
    owner_email = optional(string) # overrides owner_email for this project
  }))
  description = "Projects to create in the network area. The workload (VMs, LBs, DNS) is deployed into project1"
  default = {
    project1 = {
      name = "nlb-alb-nginx"
    }
  }
}

variable "service_account_key_path" {
  type        = string
  description = "Path to the STACKIT service account key JSON (required)"
  default     = "/root/.stackit/credentials.json" # e.g. "~/.stackit/credentials.json"

  validation {
    condition     = can(jsondecode(file(pathexpand(var.service_account_key_path))))
    error_message = "Set service_account_key_path in 020-variables.tf to an existing STACKIT service account key (JSON file)."
  }
}

variable "default_region" {
  default = "eu01"
}

variable "flavor" {
  type        = string
  description = ""
  default     = "m1.2"
}

variable "public_key_file" {
  type        = string
  description = "Path to the SSH public key for the servers (required)"
  default     = "" # e.g. "~/.ssh/id_ed25519.pub"

  validation {
    condition     = can(regex("^(ssh-|ecdsa-|sk-)", file(pathexpand(var.public_key_file))))
    error_message = "Set public_key_file in 020-variables.tf to an existing SSH public key file (e.g. ~/.ssh/id_ed25519.pub)."
  }
}

variable "servers" {
  type        = map(string)
  description = "nginx servers behind the ALBs: name => availability zone"
  default = {
    srv1 = "eu01-1"
    srv2 = "eu01-2"
    srv3 = "eu01-3"
  }
}

variable "alb_count" {
  type        = number
  description = "Number of ALBs behind the NLB. Each ALB handles up to 10,000 concurrent connections (plan p10)"
  default     = 2
}

variable "alb_plan" {
  type        = string
  description = "Service plan of the ALBs"
  default     = "p10"
}

variable "nlb_plan" {
  type        = string
  description = "Service plan of the NLB: p10 = 10,000, p50 = 50,000, p250 = 250,000, p750 = 750,000 concurrent connections"
  default     = "p50"
}

variable "dns_zone_name" {
  type        = string
  description = "DNS zone, must be globally unique below runs.onstackit.cloud"
  default     = "nlbalb.runs.onstackit.cloud"
}

variable "dns_record_name" {
  type        = string
  description = "Record name in the zone, results in <record>.<zone>"
  default     = "web"
}

variable "tls_cert_file" {
  type        = string
  description = "Optional: path to a PEM certificate (incl. chain) for the ALB. Empty = self-signed"
  default     = ""
}

variable "tls_key_file" {
  type        = string
  description = "Optional: path to the PEM private key of tls_cert_file"
  default     = ""
}


variable "ssh_server" {
  type        = string
  description = "Server that gets the management interface with public IP for SSH"
  default     = "srv1"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Source range allowed to SSH to the public IP. Restrict to your own IP, e.g. 1.2.3.4/32"
  default     = "0.0.0.0/0"
}
