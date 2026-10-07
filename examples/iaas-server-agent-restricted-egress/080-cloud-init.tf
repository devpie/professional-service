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

locals {
  # --- jump host ---------------------------------------------------------
  #
  # sshd reads the files in /etc/ssh/sshd_config.d before the rest of its
  # configuration. The main file sets no port, so this file alone decides
  # where sshd listens.
  jump_sshd_config = <<-EOT
    # Jump host: sshd listens on TCP ${local.jump_ssh_port} only and accepts public keys only.
    Port ${local.jump_ssh_port}
    PermitRootLogin no
    PubkeyAuthentication yes
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    AuthenticationMethods publickey
    # ProxyJump opens a forwarded TCP connection to the target.
    AllowTcpForwarding yes
    AllowAgentForwarding no
    X11Forwarding no
  EOT

  # Ubuntu 24.04 starts sshd through socket activation: systemd holds the
  # listening socket in ssh.socket, and a generator derives its port from the
  # sshd configuration. "systemctl daemon-reload" runs the generator again, and
  # the restart of ssh.socket closes port 22 and opens the new port. The other
  # branch covers an image that runs sshd as the plain service ssh.service.
  jump_user_data = join("\n", [
    "#cloud-config",
    yamlencode({
      write_files = [{
        path        = "/etc/ssh/sshd_config.d/00-jump-host.conf"
        owner       = "root:root"
        permissions = "0644"
        content     = local.jump_sshd_config
      }]
      runcmd = [
        "systemctl daemon-reload",
        "if systemctl is-enabled --quiet ssh.socket; then systemctl restart ssh.socket; else systemctl restart ssh.service; fi",
      ]
    }),
  ])

  # --- target ------------------------------------------------------------
  #
  # The user data of the target is a single boothook and no cloud-config.
  # cloud-init merges the cloud-config of the user over the cloud-config of
  # the vendor data: where both set a key, the value of the user wins. The
  # platform installs the Server Agent through vendor data. A boothook is a
  # script of its own and merges with nothing, so this user data overrides
  # nothing the platform delivers. A boothook is also the earliest point at
  # which user data runs.
  target_user_data = join("\n", [
    "#cloud-boothook",
    file("${path.module}/files/egress-probe-boothook.sh"),
  ])
}
