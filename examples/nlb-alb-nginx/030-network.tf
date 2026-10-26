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

// ------- project 1 - landingzone ------------
// This file defines the network setup for the first project landingzone.
locals {
  project_id = module.project.project_info["project1"].project_id
}

// Management network for SSH access via public IP
resource "stackit_network" "wan_network" {
  project_id       = local.project_id
  name             = "wan_network"
  ipv4_nameservers = ["1.1.1.1", "8.8.8.8"]
  ipv4_prefix      = "10.220.0.0/24"
  routed           = true
}

// Network for NLB, ALBs and servers
resource "stackit_network" "lan_network1" {
  project_id  = local.project_id
  name        = "lan_network1"
  ipv4_prefix = "10.220.1.0/24"
  routed      = true
}

// One network interface per server
resource "stackit_network_interface" "srv" {
  for_each           = var.servers
  project_id         = local.project_id
  network_id         = stackit_network.lan_network1.network_id
  name               = each.key
  security           = true
  security_group_ids = [stackit_security_group.srv.security_group_id]
}

// Additional management interface with public IP for SSH (attached to var.ssh_server)
resource "stackit_network_interface" "mgmt" {
  project_id         = local.project_id
  network_id         = stackit_network.wan_network.network_id
  name               = "MGMT"
  security           = true
  security_group_ids = [stackit_security_group.ssh.security_group_id]
}

resource "stackit_public_ip" "ssh" {
  project_id           = local.project_id
  network_interface_id = stackit_network_interface.mgmt.network_interface_id
}
