<!-- tags: ske, nginx, rate-limit, kubernetes, ingress, proxy-protocol -->

# How to Forward the Real Client IP to the Ingress Controller

When your application is accessed through a Load Balancer, the original client IP may not be visible to your pods unless the **TCP Proxy Protocol** is enabled and properly configured.
STACKIT supports Proxy Protocol version 2. Please follow the steps below to ensure your application and ingress-nginx controller can correctly receive and log the original client IP.

**Reference:**
Official STACKIT documentation: [Load Balancer SKE - TCP Proxy Protocol](https://docs.stackit.cloud/stackit/en/load-balancer-ske-28476594.html#LoadBalancerSKE-TCPProxyProtocol)

---

## Prerequisites

- Terraform 1.10 or later
- STACKIT provider 0.117.0 or later
- [`fortio`](https://fortio.org/) for the load test
- An authenticated `stackit` CLI (`stackit auth login` or `stackit auth activate-service-account`) and `kubectl` to read the controller log

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

`terraform.tfvars` needs `stackit_project_id`. Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).

The configuration creates an SKE cluster, a DNS zone below `runs.onstackit.cloud`, a public IP, ingress-nginx and an nginx demo deployment. The Ingress of the demo deployment accepts 10 requests per second from each client IP. The STACKIT load balancer passes the client IP to the pods only with the Proxy Protocol, so this limit depends on it.

---

## 1. Configure the Service for Proxy Protocol

The Kubernetes `Service` of type `LoadBalancer` must be annotated to enable Proxy Protocol support from STACKIT.

**Example:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-proxy-service
  annotations:
    lb.stackit.cloud/tcp-proxy-protocol: "true"
spec:
  selector:
    app: MyApp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

**Note:**
Make sure the application behind the Load Balancer is compatible with Proxy Protocol v2. If not, connections might fail or behave unexpectedly.

---

## 2. Enable Proxy Protocol on ingress-nginx

Your ingress controller must also be configured to accept Proxy Protocol headers.
This may require special Helm values when deploying ingress-nginx.

- See how this is done in [07-helm.tf](07-helm.tf) for this repository.
- In general, for ingress-nginx Helm charts, you will need:
  - `controller.config.use-proxy-protocol: "true"`
  - Any additional Service annotations as required by your cloud provider and use case.

---

## 3. Testing

To load test your endpoint and validate real client IP handling, you can use [`fortio`](https://fortio.org/):

```sh
fortio load --qps 50 -t 10s "http://$(terraform output -raw url)/"
```

Once a client exceeds the limit and its burst allowance of five times the limit, the controller answers with HTTP status 503.

The controller log shows the client IP at the start of each access log line:

```sh
eval "$(terraform output -raw kubeconfig_command)"
kubectl config use-context "$(terraform output -raw ske_cluster_name)"
kubectl logs -n nginx -l app.kubernetes.io/component=controller --tail 20
```

---

## Important

- Proxy Protocol must be enabled on **both** the Load Balancer service **and** the ingress/nginx controller.
- If either is not configured, the original client IP will not be visible within your pods, and may result in errors.
- Always review the official documentation for your platform and ingress-nginx version.

---
