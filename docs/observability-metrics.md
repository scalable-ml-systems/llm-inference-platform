📏 LLM Inference Platform — Measurement Contract

If it’s not measured, it’s not a platform.

1️⃣ Traffic & Workload Metrics (Ingress → Router → Backend)

These establish demand shape and are required before tuning.

Core

Requests per second (RPS)

Concurrent in-flight requests

Request queue depth

Request size distribution (prompt tokens)

Response size distribution (generated tokens)

Why it matters

Defines batching potential

Drives KV cache pressure

Explains tail latency

2️⃣ Latency Metrics (Golden Signals)

Measured end-to-end and per stage.

Required

p50 / p95 / p99 end-to-end latency

Time to First Token (TTFT)

Inter-token latency

Queue wait time

Breakdown

Router latency

Scheduler latency

Model execution latency

Token streaming latency

Why it matters

Continuous batching improves throughput but hurts TTFT

Tail latency reveals GPU saturation and KV eviction

3️⃣ Token Metrics (THIS IS CRITICAL)

Tokens are the currency of LLM platforms.

Core Token KPIs

Input tokens/sec

Output tokens/sec

Total tokens/sec (per GPU)

Tokens per request

Tokens per batch

Efficiency Metrics

Tokens per GPU-second

Tokens per GPU-hour

Cost per 1k tokens (Week 4)

Why it matters

This is how you:

Compare models

Compare batch strategies

Justify cost optimizations

4️⃣ Continuous Batching Metrics (vLLM-specific)

These validate batching effectiveness.

Required

Batch size over time

Average active sequences per batch

Batch fill ratio

Batch wait time

Health Indicators

Low batch size + high latency = underutilization

High batch size + high TTFT = over-batching

5️⃣ KV Cache Metrics (Paged Attention Focus)

This is where vLLM differentiates.

Core

KV cache memory usage

KV cache hit rate

KV cache eviction rate

Paged attention page faults

Active sequences in cache

Failure Indicators

Rising eviction rate → latency spikes

Page faults → memory fragmentation

Why it matters

This directly proves:

“Paged attention enables higher concurrency without OOM.”

6️⃣ GPU Metrics (From DCGM)

These prove you are running a GPU platform, not just Kubernetes.

Utilization

GPU SM utilization (%)

GPU memory utilization (%)

GPU power draw (W)

GPU temperature

Efficiency

GPU idle time

GPU utilization vs tokens/sec

GPU memory fragmentation

Why it matters

High GPU utilization without high tokens/sec is a red flag.

7️⃣ Memory Metrics (OOM Prevention)
Required

GPU memory used vs available

Host memory usage

OOM events

CUDA allocation failures

Correlated With

Batch size

KV cache pressure

Prompt length spikes

8️⃣ Multi-Model Readiness Metrics (Even Before You Enable It)

Even in single-model Phase 1, track these as labels.

Per-Model Labels

model_name

model_version

tensor_parallelism

gpu_type

Metrics

Tokens/sec per model

Latency per model

GPU utilization per model

This makes Week 3–4 multi-model expansion trivial.

9️⃣ Reliability & Failure Metrics
Core

HTTP / gRPC error rate

Timeouts

Pod restarts

Node terminations

Request retries

Tail Risk

Latency during failure

Recovery time (MTTR)

🔟 Production-Grade SRE Signals (Non-Negotiable)

These elevate this from “ML demo” to infra platform.

Golden Signals
Signal	Metric
Latency	p50 / p95 / p99
Traffic	RPS, tokens/sec
Errors	4xx / 5xx
Saturation	GPU %, KV cache pressure
11️⃣ Cost Metrics (Week 4 Focus)
Required

GPU-hours consumed

Cost per request

Cost per 1k tokens

Idle GPU cost

This is where the platform becomes business-credible.

12️⃣ Metric Naming Discipline (Important)

You will want metrics like:

llm_requests_total

llm_tokens_input_total

llm_tokens_output_total

llm_batch_size

llm_kv_cache_hit_ratio

gpu_utilization

gpu_memory_used_bytes

llm_latency_bucket

Consistent names → defensible dashboards.

What This Proves (Big Picture)

With this measurement set, you can demonstrate:

Continuous batching improves throughput

Paged attention prevents OOM

KV cache efficiency scales concurrency

GPU utilization correlates with token throughput

Cost is measurable and optimizable

Platform is production-ready
