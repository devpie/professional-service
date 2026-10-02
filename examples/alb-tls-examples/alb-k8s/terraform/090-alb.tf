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

# This example sends Ingress traffic through Traefik behind a STACKIT Network
# Load Balancer. For a STACKIT Application Load Balancer as the Ingress of an
# SKE cluster, see examples/ske-alb-controller-waf-extension (SKE runs the ALB
# controller) and examples/ske-alb-controller-waf-self-installed (the
# configuration deploys the ALB controller into the cluster).
