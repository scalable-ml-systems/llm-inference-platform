# vLLM Inference Platform — Notion Checklist

## Week 1 — Phase 0 & Phase 1: Base Cluster + Single‑Node Backend

### Terraform Tasks (Infra Setup)
[x] Terraform AWS provider setup (provider.tf)
[x] VPC + Subnets + Security Groups
[x] EKS cluster with GPU node group (EC2 P4/P5)
[x] IAM roles / service accounts for cluster & nodes
[x] S3 bucket for models
[x] FSx for Lustre caching

### Helm Tasks
[ ] Prometheus + Grafana + Loki
- Install via helm_release in modules/observability/
- Wire Grafana dashboards (vllm-metrics.json, gpu-utilization.json, cost-tracking.json)
- IRSA role for Prometheus (prometheus_irsa_role_arn)

[ ] DCGM exporter
- Install via Helm in gpu-metrics namespace
- Exposes GPU utilization, memory, temperature metrics
- Scraped by Prometheus

👉 Once this is done, you’ll have full observability: GPU utilization, latency, throughput, and cost dashboards.

### vLLM Deployment
[ ] Single‑GPU vLLM deployment via Helm chart
- Helm chart in vllm/ namespace
- ServiceAccount annotated with IRSA (vllm_irsa_role_arn)
- Pull models from S3, cache hot models in FSx

[ ] FastAPI / gRPC endpoint setup
- Expose via ALB ingress (from networking/ module)
- gRPC for high‑throughput inference, FastAPI for REST

[ ] Request batching + warm‑up logic
- Configure vLLM’s --enable-batching
- Warm‑up models on startup to avoid cold latency

👉 This phase delivers a production‑ready inference endpoint.

Deliverables / Artifacts
[ ] Latency report (p50/p95/p99)

[ ] Architecture diagram

[ ] Grafana dashboard (GPU metrics visible)

LinkedIn / Blog Prompt
[ ] “Built the foundation for a high-performance vLLM inference platform: infrastructure as code + single-node deployment.”

Week 2 — Phase 2: GPU Memory & Throughput Engineering
Terraform / Helm Tasks
[ ] Update node group to multi‑GPU nodes

[ ] Verify GPU scheduling + CUDA drivers

vLLM Tasks
[ ] Batch size tuning

[ ] Concurrency control for requests

[ ] KV cache / embedding cache integration

[ ] Stress testing under load

Deliverables / Artifacts
[ ] Batch vs throughput graph

[ ] GPU memory profiling dashboard

[ ] OOM postmortem

LinkedIn / Blog Prompt
[ ] “Scaling vLLM inference: optimizing GPU memory and throughput for multi-GPU workloads”

Week 3 — Phase 3: Kubernetes Scaling & Orchestration
Terraform Tasks
[ ] GPU node pools with taints/tolerations

[ ] Horizontal Pod Autoscaler configuration

[ ] Node affinity rules

Helm / vLLM Tasks
[ ] Multi‑node vLLM deployment

[ ] Scaling tests under concurrent load

[ ] Monitor scheduling latency + GPU utilization

Deliverables / Artifacts
[ ] Autoscaling dashboards

[ ] GPU utilization charts

[ ] Scheduling latency metrics

LinkedIn / Blog Prompt
[ ] “Scaling production vLLM inference on Kubernetes: lessons from GPU orchestration and autoscaling”

Week 4 — Phase 4 & Phase 5: Failure Injection + Cost Optimization
Failure Injection
[ ] Inject pod kills / node eviction under load

[ ] Simulate GPU OOM events

[ ] Track p50/p95/p99 latency impact

Observability
[ ] Full metrics setup (GPU memory, utilization, tokens/sec, latency)

[ ] Alerting rules in Prometheus / Alertmanager

Cost Optimization
[ ] Track GPU‑hour cost per 1k tokens

[ ] Batch vs latency vs GPU‑hour cost analysis

[ ] Tune HPA / node pool policies for cost‑efficiency

Deliverables / Artifacts
[ ] Incident timelines + dashboards

[ ] Cost efficiency report

[ ] Postmortems for failures & OOMs

LinkedIn / Blog Prompt
[ ] “Optimizing vLLM inference for resilience, observability, and GPU cost efficiency”


### Semantic Intelligent Router for Models 