<!-- tags: ske, gpu, kubernetes, nvidia, operator, h100 -->

# SKE Kubernetes GPU Operator Installation

## Overview

This example demonstrates how to deploy a SKE cluster with an NVIDIA H100 node pool and install the GPU Operator.

**Note:** Currently, GPU-enabled node pools on SKE are only supported when using Ubuntu as the node operating system.

## Kubernetes version

The variable `kubernetes_version_min` keeps the cluster on Kubernetes 1.35.
Kubernetes 1.36 needs containerd 2.0, and SKE Ubuntu 22.04 nodes do not support it ([SKE release notes](https://docs.stackit.cloud/products/runtime/kubernetes-engine/release-notes/), 2026-08-27).
The GPU Operator supports only node pools with Ubuntu ([Use NVIDIA GPUs](https://docs.stackit.cloud/products/runtime/kubernetes-engine/how-tos/use-nvidia-gpus/)).

SKE expires Kubernetes 1.35 on 2027-02-10 ([lifecycle](https://docs.stackit.cloud/products/runtime/kubernetes-engine/reference/lifecycle/)).
From that date, SKE creates no new 1.35 clusters and moves existing ones to a higher version in their maintenance window ([version updates](https://docs.stackit.cloud/products/runtime/kubernetes-engine/basics/operations/version-updates/)).
