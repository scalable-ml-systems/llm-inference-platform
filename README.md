# LLM Inference Platform - 

## UNDER ACTIVE BUILD

This repository is an applied project that explores production-grade LLM inference infrastructure patterns on AWS EKS, with a focus on performance, cost optimization, observability, and security.

STATUS : 

Inference Backend Milestone — Artifact Summary

Status: COMPLETE & VERIFIED

Two LLMs successfully deployed:

LLaMA-3.1-8B (AWQ INT4)

Mistral-7B Instruct (AWQ)

Infrastructure: AWS EKS with 2 dedicated GPU nodes (g4dn.xlarge)

Placement:

1 model per GPU node (no GPU oversubscription)

Inference Engine: vLLM with TRITON_ATTN

API: OpenAI-compatible (/v1/models, /v1/chat/completions)

Operational State:

Models fully loaded

Backends stable (no CrashLoop, no Pending pods)

Ready for live inference traffic

Result:
 Both LLaMA and Mistral are serving inference concurrently on separate GPUs, with deterministic scheduling and production-safe rollout behavior.


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
