# Platform Setup — Running the LLM Inference System

This document describes how to **provision, deploy, and run** the LLM inference platform end to end.

The setup follows the platform’s layered architecture:
- Infrastructure is provisioned first
- Core services are deployed in order
- Observability is verified before load is applied

---

## Prerequisites

### Local Tools
- Terraform ≥ 1.5
- kubectl
- Helm
- AWS CLI
- Docker

### Cloud Requirements
- AWS account with permissions to create:
  - VPC
  - EKS cluster
  - EC2 (GPU and system node groups)
  - IAM roles
- GPU quota available in the target region

---

## Step 1 — Provision Infrastructure (Terraform)

All infrastructure is managed via Terraform.

### Configure Environment
```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars with:

AWS region

Cluster name

Node group sizes

GPU instance types

Initialize and Apply
terraform init
terraform apply

```

### IAC provisions:
 - VPC and networking
 - EKS cluster
 - System and GPU node groups
 - Core IAM roles
 - Observability stack (Prometheus, Grafana, Loki, Tempo)

### Verify cluster access:
```
kubectl get nodes
```

### Step 2 — Deploy Observability Stack

Observability is deployed early to ensure visibility during subsequent steps.

kubectl get pods -n observability


### Confirm:
 - Prometheus is scraping
 - Grafana is reachable
 - DCGM exporter is running on GPU nodes

At this point, dashboards should be available but mostly empty.

### Step 3 — Deploy Inference Backends (Layer 3)

Inference backends are deployed via Helm.

```
Install Backend A
helm upgrade --install backend-a \
  deployment/charts/inference-backend \
  -f deployment/values/values-backend-a.yaml \
  -n inference-backend

Install Backend B
helm upgrade --install backend-b \
  deployment/charts/inference-backend \
  -f deployment/values/values-backend-b.yaml \
  -n inference-backend
```

### Warmup Job: 

Each backend includes a warmup job that:
 - Loads model weights
 - Initializes CUDA kernels
 - Prepares KV cache paths

Wait until warmup completes:

```
kubectl get jobs -n inference-backend
```

Backends should not receive traffic until warmup is complete.

### Step 4 — Deploy Router Service (Layer 2)

The router is deployed after inference backends are healthy.

```
kubectl apply -f services/router-service/k8s/


Verify:

kubectl get pods -n router
kubectl logs -n router deploy/router-service

```

### Ensure:

 - Router config is loaded
 - Routing rules are parsed
 - Health endpoints return ready

### Step 5 — Deploy Edge Gateway (Layer 1)
The Edge Gateway exposes the platform entry point.

```
helm upgrade --install edge-gateway \
  services/edge-gateway/helm/edge-gateway \
  -n edge
```


### Confirm ingress/service endpoint:
```
kubectl get svc -n edge

```

### Step 6 — Verify End-to-End Flow

Run a basic smoke test:

```
services/inference-backend/scripts/smoke_test.sh
```

### Expected behavior:

 - Requests flow through Edge → Router → Backend
 - Responses are returned successfully
 - Metrics begin populating Grafana dashboards

### Step 7 — Validate Observability

 Open Grafana and confirm:
  - Request rate is visible
  - TTFT metrics are present
  - GPU utilization and memory metrics are populated
  - This confirms Layer 4 is fully wired.

### Step 8 — Apply Load
Use the provided load-testing scripts:

 - Fixed RPS
 - Ramp load
 - Mixed-model traffic

Run load only after observability is confirmed working.

Under load, expect:
 - GPU utilization to approach saturation
 - TTFT to increase gradually
 - No sudden error spikes

This is normal and observable behavior.

### Operational Notes

The platform is designed to be GPU-saturated

 - High utilization is expected
 - Latency behavior should remain explainable via dashboards
 - Routing and capacity decisions are made upstream, not in the backend

### Shutting Down (Cost Control)
To stop GPU usage:

```
infrastructure/scripts/nightoff.sh

To resume:

infrastructure/scripts/resume-dev.sh
```

### Summary
Following this sequence ensures:
 - Infrastructure is stable before services start
 - Backends are warm before traffic arrives
 - Observability is available before load
 - System behavior can be reasoned about at every stage

This setup mirrors how the platform is intended to be operated in practice.