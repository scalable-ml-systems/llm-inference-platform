# LLM Inference Platform - 

## UNDER ACTIVE BUILD

This repository contains a production-oriented LLM inference platform designed to serve large language models with explicit guarantees around performance, cost, observability, and safety.

<img width="800" height="800" alt="vllm-inference-platform-complete" src="https://github.com/user-attachments/assets/110f2d8c-2a21-4977-bc62-0795161ee41d" />


The platform focuses on runtime inference concerns:
- multi-model serving
- intelligent request routing
- GPU-efficient batching and concurrency
- AI-specific observability (latency, tokens/sec, GPU utilization)
- cost-per-token visibility
- evaluation and safety guardrails

This system intentionally does NOT cover model training or large-scale fine-tuning.
The goal is to model how LLMs are actually operated in production environments.

Initial deployment targets AWS EKS with GPU-backed nodes.

## ACTIVE BUILD : 

Repo Structure

```

llm-inference-platform/
├── services/
│   ├── router/
│   │   ├── app.py                # FastAPI router service (entry point, routing logic)
│   │   ├── metrics.py            # Prometheus metrics: cost per token, routing distribution, latency
│   │   ├── context_registry.py   # Redis KV registry for context affinity (session/prefix mapping)
│   │   ├── semantic_classifier.py# Stub for easy/hard prompt detection (Mistral vs Llama routing)
│   │   ├── requirements.txt      # Python dependencies for router service
│   │   └── Dockerfile            # Container build for router
│   │
│   └── vllm/
│       ├── config.yaml           # vLLM runtime configs (batching, cache tuning, offload settings)
│       ├── metrics_exporter.py   # Prometheus exporter: KV cache hits/misses, batching stats, OOM events
│       ├── warmup.py             # Model warm-up logic (cold start latency tracking)
│       ├── requirements.txt      # Python dependencies for vLLM service
│       └── Dockerfile            # Container build for vLLM
│
├── infra/
│   ├── terraform/                # Infrastructure as code (AWS, EKS, IAM, FSx, S3, etc.)
│   │   ├── provider.tf
│   │   ├── versions.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── modules/
│   │       ├── vpc/              # Networking
│   │       ├── security/         # Security groups, IAM policies
│   │       ├── iam/              # IRSA roles for router/vLLM
│   │       ├── eks/              # EKS cluster setup
│   │       ├── storage/          # FSx + S3 buckets
│   │       ├── ecr/              # Container registry
│   │       ├── kms/              # Encryption keys
│   │       ├── cicd/             # CI/CD pipelines
│   │       ├── observability/    # Terraform-managed observability (optional)
│   │       ├── autoscaling/      # GPU autoscaling policies
│   │       ├── cost-management/  # Cost dashboards + budgets
│   │       ├── networking/       # ALB, NLB configs
│   │       ├── secrets/          # Secret management
│   │       ├── disaster-recovery/# Backup + restore
│   │       └── testing/          # Infra validation
│   │
│   └── kubernetes/               # K8s manifests + Helm values
│       ├── vllm/
│       │   ├── values.yaml       # Helm values for vLLM deployment
│       │   ├── deployment.yaml   # vLLM Deployment manifest
│       │   ├── service.yaml      # vLLM Service manifest
│       │   └── ingress.yaml      # vLLM Ingress manifest
│       ├── router/
│       │   ├── values.yaml       # Helm values for router deployment
│       │   ├── deployment.yaml   # Router Deployment manifest
│       │   ├── service.yaml      # Router Service manifest
│       │   └── ingress.yaml      # Router Ingress manifest
│       └── observability/
│           ├── values/
│           │   ├── kube-prometheus-stack-values.yaml
│           │   ├── loki-values.yaml
│           │   └── dcgm-values.yaml
│           └── dashboards/
│               ├── vllm-metrics.json        # Latency, throughput, batching efficiency
│               ├── gpu-utilization.json     # GPU usage, memory, temperature
│               └── cost-tracking.json       # Cost per token, GPU-hour cost
│
├── tests/
│   ├── unit/
│   │   ├── test_router_metrics.py           # Validates router Prometheus counters
│   │   └── test_vllm_metrics.py             # Validates vLLM exporter metrics
│   ├── integration/
│   │   └── test_end_to_end.py               # End-to-end smoke tests across router + vLLM
│   └── load/
│       └── locustfile.py                    # Load tests for batching efficiency
│
├── benchmarks/
│   ├── router_benchmark.py                  # Benchmark routing decisions
│   └── results/                             # Store benchmark outputs
│
├── docs/
│   └── ARCHITECTURE.md                      # System architecture overview
│
└── scripts/
    └── deploy.sh                            # One-click deploy (Terraform + Helm)

```
