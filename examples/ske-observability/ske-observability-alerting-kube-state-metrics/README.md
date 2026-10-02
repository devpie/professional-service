<!-- tags: ske, observability, alerting, prometheus, kube-state-metrics, kubernetes -->

# SKE Observability alerting with Kube-State-Metrics

## Overview

This guide explains how to configure the STACKIT Observability product to send alerts using metrics gathered from kube-state-metrics.

The example creates an SKE cluster and an Observability instance in one project.
The Helm chart `kube-prometheus-stack` runs Prometheus in agent mode, together with kube-state-metrics and the node exporter.
Prometheus forwards the series with the label `namespace="example"` to the metrics push URL of the instance.
The alert group in `050-alertgroup.tf` fires while a pod in that namespace runs.
The Alertmanager routing in `030-observability.tf` sends the notification by email.

## Prerequisites

- STACKIT provider 0.117.0 or later
- An authenticated `stackit` CLI (`stackit auth login` or `stackit auth activate-service-account`) and `kubectl` for the verify step

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

`terraform.tfvars` needs `stackit_project_id` and `alert_email`.
Without `stackit_service_account_key_path`, the provider falls back to `STACKIT_SERVICE_ACCOUNT_KEY_PATH`, then to its credentials file `$HOME/.stackit/credentials.json` ([provider authentication](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)).
Without `kubernetes_version_min`, SKE creates the cluster on the latest Kubernetes version it supports.

## Verify

Open the Grafana URL, select the data source `Thanos` in Explore and query the phase of the demo pod:

```bash
terraform output -raw grafana_url
```

```promql
kube_pod_status_phase{namespace="example", phase="Running"}
```

Check the demo pod with `kubectl`:

```bash
eval "$(terraform output -raw kubeconfig_command)"
kubectl config use-context "$(terraform output -raw ske_cluster_name)"
kubectl get pod nginx -n example
```
