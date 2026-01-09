services/ → Application logic (router + vLLM) and metrics trackers

infra/terraform/ → AWS infra modules (EKS, FSx, IAM, autoscaling, cost mgmt)

infra/kubernetes/ → Helm values + manifests for workloads and observability

tests/ → Unit, integration, and load tests for metrics + routing

benchmarks/ → Performance benchmarks for router decisions

docs/ARCHITECTURE.md → Layered architecture explanation (Ingress, Router, Semantic Controller, Inference Engine, Memory Fabric, Observability)

scripts/deploy.sh → One-click deploy script
