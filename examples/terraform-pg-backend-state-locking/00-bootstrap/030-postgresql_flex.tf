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

data "stackit_postgresflex_flavors" "this" {
  project_id = stackit_resourcemanager_project.this.project_id
}

# Provision PostgreSQL Flex Database Instance
resource "stackit_postgresflex_instance" "this" {
  project_id = stackit_resourcemanager_project.this.project_id
  name       = "tf-state-instance"
  version    = "17"

  flavor_id = one([for f in data.stackit_postgresflex_flavors.this.flavors : f.id if f.cpu == 2 && f.memory == 4 && f.node_type == "Single"])
  storage = {
    class = "premium-perf2-stackit"
    size  = 10
  }

  backup_schedule = "0 0 * * *"
  retention_days  = 32

  network = {
    acl = [
      # WARNING: Open ACL is for development only. Restrict to your specific egress IP ranges in production.
      "0.0.0.0/0"
    ]
  }

}

# Provision PostgreSQL Flex Database Owner
resource "stackit_postgresflex_user" "db_owner" {
  project_id  = stackit_resourcemanager_project.this.project_id
  instance_id = stackit_postgresflex_instance.this.instance_id
  username    = "tf_state_user"
  roles       = ["login", "createdb"]
}

# Provision PostgreSQL Flex Database
resource "stackit_postgresflex_database" "this" {
  project_id  = stackit_resourcemanager_project.this.project_id
  instance_id = stackit_postgresflex_instance.this.instance_id
  owner       = stackit_postgresflex_user.db_owner.username
  # The v3 API accepts lowercase letters, digits and underscores only.
  name = "terraform_state"
}
