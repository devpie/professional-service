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

output "sna_id" {
  description = "ID of the STACKIT Network Area"
  value       = stackit_network_area.sna.network_area_id
}

output "ske_project_id" {
  description = "Project ID for the SKE cluster"
  value       = stackit_resourcemanager_project.ske_project.project_id
}

output "nlb_project_id" {
  description = "Project ID for the external NLB"
  value       = stackit_resourcemanager_project.nlb_project.project_id
}

output "cluster_name" {
  description = "Name of the SKE cluster"
  value       = stackit_ske_cluster.main.name
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version used by the cluster"
  value       = stackit_ske_cluster.main.kubernetes_version_used
}

output "dns_zone_id" {
  description = "ID of the DNS zone"
  value       = stackit_dns_zone.this.zone_id
}

output "dns_zone_domain" {
  description = "DNS zone domain name"
  value       = stackit_dns_zone.this.dns_name
}

output "app_domain" {
  description = "Full domain name for the application (app.{dns_zone_domain})"
  value       = "app.${var.dns_zone_domain}"
}

output "external_nlb_ip" {
  description = "Public IP of the external NLB"
  value       = stackit_public_ip.nlb_ip.ip
}

output "internal_lb_ip" {
  description = "Private SNA IP of the internal LoadBalancer"
  value       = kubernetes_service_v1.nginx_internal_lb_tls.status[0].load_balancer[0].ingress[0].ip
}

output "ske_kubeconfig" {
  description = "Full kubeconfig for the SKE cluster"
  value       = stackit_ske_kubeconfig.ske.kube_config
  sensitive   = true
}
