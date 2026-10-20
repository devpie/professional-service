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

# cloud-init installs the key of the key pair for the default user of the
# image. Both machines use it.
resource "stackit_key_pair" "admin" {
  name       = "${var.name_prefix}-admin"
  public_key = chomp(var.ssh_public_key)
}

# --- jump host -----------------------------------------------------------
#
# The only machine with a public IP. Its network interface carries the jump
# host's security group and no other.
resource "stackit_network_interface" "jump" {
  project_id         = local.project_id
  network_id         = stackit_network.this.network_id
  name               = "${var.name_prefix}-jump"
  security           = true
  security_group_ids = [stackit_security_group.jump.security_group_id]
}

resource "stackit_public_ip" "jump" {
  project_id           = local.project_id
  network_interface_id = stackit_network_interface.jump.network_interface_id
}

resource "stackit_server" "jump" {
  project_id         = local.project_id
  name               = "${var.name_prefix}-jump"
  availability_zone  = var.availability_zone
  machine_type       = var.jump_machine_type
  keypair_name       = stackit_key_pair.admin.name
  network_interfaces = [stackit_network_interface.jump.network_interface_id]
  user_data          = templatefile("${path.module}/jump-host-cloud-init.yaml.tftpl", { ssh_port = local.jump_ssh_port })

  boot_volume = {
    source_type           = "image"
    source_id             = var.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true
  }

  # The jump host only forwards SSH. It gets no Server Agent.
  agent = {
    provisioning_policy = "NEVER"
  }
}

# --- target --------------------------------------------------------------
#
# The network interface is created after the rule set of its security group
# is complete: the default egress rules are gone and every rule of the
# allow-list exists. The server needs the interface, so its first boot already
# runs under the final rule set. cloud-init and the installation of the Server
# Agent happen during that first boot.
resource "stackit_network_interface" "target" {
  project_id         = local.project_id
  network_id         = stackit_network.this.network_id
  name               = "${var.name_prefix}-target"
  security           = true
  security_group_ids = [stackit_security_group.target.security_group_id]

  depends_on = [
    terraform_data.remove_default_egress_rules,
    stackit_security_group_rule.target_egress,
    stackit_security_group_rule.target_ssh,
  ]
}

resource "stackit_server" "target" {
  project_id         = local.project_id
  name               = "${var.name_prefix}-target"
  availability_zone  = var.availability_zone
  machine_type       = var.target_machine_type
  keypair_name       = stackit_key_pair.admin.name
  network_interfaces = [stackit_network_interface.target.network_interface_id]

  # A server created from an image gets a new boot volume. A replaced server
  # therefore starts from the unchanged image and runs its first boot again.
  boot_volume = {
    source_type           = "image"
    source_id             = var.image_id
    size                  = var.boot_volume_size
    delete_on_termination = true
  }

  # The platform installs the STACKIT Server Agent during the first boot.
  agent = {
    provisioning_policy = "ALWAYS"
  }

  depends_on = [
    terraform_data.remove_default_egress_rules,
    stackit_security_group_rule.target_egress,
    stackit_security_group_rule.target_ssh,
  ]
}
