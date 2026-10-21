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

# ── cert-manager Namespace ─────────────────────────────────────────

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/instance" = "cert-manager"
    }
  }
}

# ── cert-manager Helm Release ──────────────────────────────────────

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  values = [yamlencode({
    installCRDs = true
  })]
}

# ── STACKIT cert-manager Webhook ────────────────────────────────────

resource "helm_release" "stackit_webhook" {
  name       = "stackit-cert-manager-webhook"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
  repository = "https://stackitcloud.github.io/stackit-cert-manager-webhook"
  chart      = "stackit-cert-manager-webhook"
  version    = var.stackit_cert_manager_webhook_chart_version

  values = [yamlencode({
    stackitSaAuthentication = {
      enabled = true
    }
  })]

  depends_on = [helm_release.cert_manager]
}

# ── STACKIT Service Account Key (for DNS-01 validation) ────────────
# The webhook reads this secret from the cert-manager namespace.

resource "kubernetes_secret_v1" "stackit_sa_key" {
  metadata {
    name      = "stackit-sa-authentication"
    namespace = kubernetes_namespace_v1.cert_manager.metadata[0].name
  }

  data = {
    "sa.json" = file(var.stackit_service_account_key_path)
  }

  type = "Opaque"

  depends_on = [helm_release.stackit_webhook]
}

# ── ClusterIssuer (STACKIT DNS-01 via Let's Encrypt) ───────────────

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            dns01 = {
              webhook = {
                solverName = "stackit"
                groupName  = "acme.stackit.de"
                config = {
                  projectId = stackit_resourcemanager_project.ske_project.project_id
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager, helm_release.stackit_webhook, kubernetes_secret_v1.stackit_sa_key]
}

# ── Certificate ────────────────────────────────────────────────────

resource "kubernetes_manifest" "nginx_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "nginx-tls"
      namespace = "default"
    }
    spec = {
      secretName = "nginx-tls"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "app.${var.dns_zone_domain}",
      ]
    }
  }

  depends_on = [kubernetes_manifest.cluster_issuer]
}

# ── Nginx TLS ConfigMap ────────────────────────────────────────────

resource "kubernetes_config_map_v1" "nginx_tls_config" {
  metadata {
    name      = "nginx-tls-config"
    namespace = "default"
  }

  data = {
    "nginx.conf" = <<-EOT
        events {
          worker_connections 1024;
        }

        http {
          server {
            listen 443 ssl;
            server_name app.${var.dns_zone_domain};

            ssl_certificate     /etc/nginx/tls/tls.crt;
            ssl_certificate_key /etc/nginx/tls/tls.key;
            ssl_protocols       TLSv1.2 TLSv1.3;
            ssl_ciphers         HIGH:!aNULL:!MD5;

            location / {
              root /usr/share/nginx/html;
              index index.html;
            }
          }
        }
    EOT
  }
}

# ── Nginx Deployment (TLS) ────────────────────────────────────────
# This replaces the plain HTTP deployment from 050-nginx.tf.

resource "kubernetes_deployment_v1" "nginx_tls" {
  metadata {
    name      = "nginx"
    namespace = "default"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = var.nginx_replicas
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = var.nginx_image

          args    = ["-g", "daemon off;"]
          command = ["nginx"]

          port {
            container_port = 443
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }

          volume_mount {
            name       = "nginx-tls"
            mount_path = "/etc/nginx/tls"
            read_only  = true
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map_v1.nginx_tls_config.metadata[0].name
          }
        }

        volume {
          name = "nginx-tls"
          secret {
            secret_name = "nginx-tls"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.nginx_certificate]
}

# ── Internal LoadBalancer Service (TLS, port 443) ──────────────────
# This replaces the port-80 service from 050-nginx.tf.

resource "kubernetes_service_v1" "nginx_internal_lb_tls" {
  metadata {
    name      = "nginx-internal-lb"
    namespace = "default"
    annotations = {
      "lb.stackit.cloud/internal-lb" = "true"
    }
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment_v1.nginx_tls]
}
