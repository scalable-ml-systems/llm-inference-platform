## Layer 4 — Observability (System Visibility)

Layer 4 exists to make the system explainable under load.
Not just to collect metrics—but to answer one operational question:

Why is latency behaving the way it is right now?

### Design Intent
This layer is built to:
- Correlate latency, throughput, and GPU behavior
- Detect saturation before failure
- Explain routing and execution outcomes
- Support capacity planning and tuning
- Stay out of the serving path
- Dashboards are diagnostic tools. Not decoration.

### Architecture
 - Observability spans the full system:
 - Metrics are centralized
 - Logs are structured and queryable
 - GPU telemetry comes straight from hardware 
 - Dashboards focus on correlation—not isolated signals
 - It runs as a side plane. It observes, never interferes.

### Metric Sources
Metrics are emitted from every layer:
 - Edge Gateway
 - Request rate
 - Error rate
 - Upstream latency
 - Router Service
 - Routing decisions
 - Retry/fallback counts
 - Router latency
 - Inference Backends
 - Time to First Token (TTFT)
 - End-to-end latency
 - Active concurrency
 - Tokens/sec
 - GPU Telemetry
 - Utilization
 -  Memory usage
 - Saturation signals

All metrics are scraped centrally with consistent labels for cross-layer queries.

### Dashboards
Dashboards are built around cause and effect.

They answer questions like:
 - Is latency due to compute or memory pressure?
 - Are certain models hogging GPU capacity?
 - Is routing aligned with policy?
 - Are we nearing saturation?

They avoid:
- Single-metric views
- Absolute performance claims
- Benchmark-style comparisons

### Core Dashboards
1. End-to-End Inference Overview  
First stop when latency shifts.
Correlates TTFT (p50/p95/p99), request rate, GPU utilization.

2. Inference ↔ GPU Correlation  
Explains how GPU behavior maps to latency.
TTFT vs GPU utilization, memory, concurrency.

3. GPU Utilization and Memory  
Tracks compute and memory usage over time.
Used for capacity planning and concurrency tuning.

4. Prefill vs Decode Behavior  
Separates prompt-heavy vs decode-heavy workloads.
Shows latency and throughput differences across models.

### Logs and Tracing
- Structured JSON
- Include request IDs and routing metadata
- Used for post-hoc debugging
- Tracing
- Optional
- Follows individual requests across layers
- Not used for steady-state monitoring

### Operating Under Load
This system assumes:
 - GPUs will saturate
 - Queueing will happen
 - Tail latency will rise before errors
 - Dashboards are built to show:
 - When it’s happening
 -  Why it’s happening
 - What lever to pull (routing, concurrency, capacity)

### What It Doesn’t Do
To preserve correctness and isolation, observability does not:
- Influence routing
- Throttle traffic
- Auto-scale
- Hide or smooth behavior
- Its job is to surface truth. Not enforce policy.

### Summary
Layer 4 makes a GPU-backed inference system observable and explainable.

It connects latency, throughput, and GPU behavior across layers—so you can:

- Operate safely under load
- Diagnose issues fast
- Plan capacity with confidence

Dashboards are built to help you reason. Not to impress.
