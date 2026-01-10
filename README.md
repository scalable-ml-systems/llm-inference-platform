## LLM Multi-Tier Inference Platform

**Status: Active Development**

A hands-on learning project exploring production-style LLM inference infrastructure patterns on AWS EKS.

This repository focuses on how modern LLM inference systems are **designed, operated, and constrained** in real environments — with an emphasis on infrastructure-as-code, routing patterns, and GPU memory management.

- Cost-effective multi-model serving strategies
- Intelligent request routing based on complexity
- GPU-efficient batching and memory management
- Production observability (latency, tokens/sec, GPU metrics)
- Infrastructure-as-code patterns for ML systems

**Scope:** Runtime inference infrastructure (not training or fine-tuning)

**Target Platform:** AWS EKS with GPU nodes (g4dn.xlarge instances)

## Current Status

### ✅ Completed
- Infrastructure-as-code (Terraform modules for VPC, EKS, IAM, storage)
- Kubernetes manifests for vLLM and router services
- Router service framework (FastAPI with metrics)
- Observability configuration (Prometheus, Grafana, Loki, DCGM)
- Project structure and documentation

### 🚧 In Progress
- Deploying infrastructure to AWS
- Testing vLLM deployment with actual models (Qwen 1.5B, LLaMA 3.2-3B)
- Implementing routing logic (currently heuristic-based)
- Validating end-to-end request flow
- Benchmarking and optimization

### ⚪ Planned (Next Phases)
- Semantic classifier (replacing current heuristic stub)
- Load testing and performance tuning
- Multi-tier caching optimization
- Production security hardening
- Cost tracking and optimization
- Comprehensive testing suite

## Architecture Overview

**Target Architecture:**
- **Router Service:** FastAPI-based request router with context affinity
- **vLLM Instances:** Two-tier deployment (fast + reasoning models)
- **Infrastructure:** AWS EKS with GPU nodes, FSx storage, managed observability
- **Monitoring:** Prometheus + Grafana for inference metrics, DCGM for GPU monitoring

**Planned Models for Validation:**
- Fast Tier: Qwen 1.5B (~3GB, latency target under light load: <100ms)
- Reasoning Tier: LLaMA 3.2-3B (~6GB, latency target under light load: <500ms)

**Infrastructure (Target):**
- 2x g4dn.xlarge nodes (T4 GPUs, 16GB VRAM each)
- Estimated cost: ~$1/hour (~$720/month)

See [docs/architecture.md](docs/architecture.md) for detailed design.

## Repository Structure
```
llm-inference-platform/
├── services/          # Application code
│   ├── router/        # Request routing service (FastAPI)
│   └── vllm/          # vLLM metrics and configuration
├── infra/             # Infrastructure-as-code
│   ├── terraform/     # AWS infrastructure (EKS, VPC, IAM, etc.)
│   └── kubernetes/    # K8s manifests and Helm values
├── tests/             # Testing framework (WIP)
├── benchmarks/        # Performance benchmarks (WIP)
├── docs/              # Architecture and setup documentation
└── scripts/           # Deployment automation
```

## Quick Start

> ⚠️ **Note:** This is under active development. Deployment steps are being validated.

### Prerequisites
- AWS account with appropriate permissions
- `terraform` >= 1.0
- `kubectl` configured for EKS
- `helm` >= 3.0

See [docs/setup/setup.md](docs/setup/setup.md) for detailed instructions.

## Technical Highlights

**Infrastructure-as-Code:**
- Modular Terraform for AWS (VPC, EKS, IAM, storage, security)
- Separate environments (dev/staging/prod)
- GitOps-ready Kubernetes manifests

**Router Design:**
- FastAPI service with Prometheus metrics
- Context affinity via Redis (planned)
- Pluggable routing logic (currently heuristic-based)

**Observability:**
- Prometheus + Grafana stack
- DCGM for GPU metrics
- Loki for log aggregation
- Custom dashboards for inference metrics

## Important Disclaimers 

⚠️ **This repository documents an evolving design, not a finished system**
- Security hardening incomplete (no auth/authz yet)
- Testing coverage minimal
- Performance not yet validated at scale
- Configurations may change frequently

⚠️ **Current Limitations:**
- Single-region deployment only
- Basic routing heuristics (semantic classifier is stub)
- No multi-tenancy support
- Minimal error handling
- Cost tracking not fully implemented

⚠️ **Building in Public:**
- You'll see experiments and iterations
- Expect TODO comments and rough edges
- Architecture decisions may change based on learnings

- Issues/questions are welcome
- Suggestions appreciated
- Feel free to fork and adapt for your use case

## Resources & References
- [vLLM Documentation](https://docs.vllm.ai/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Designing ML Systems (Chip Huyen)](https://www.oreilly.com/library/view/designing-machine-learning/9781098107956/)

## License
Apache 2.0 - See [LICENSE](LICENSE)

---
