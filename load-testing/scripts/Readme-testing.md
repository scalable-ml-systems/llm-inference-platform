Load Testing — Technical Specification

This directory contains four load-testing scripts, each targeting a different aspect of the LLM inference system.
All scripts send traffic to a single HTTP endpoint (typically the Router, Layer 2), which then fans out to inference backends.

Common Assumptions (All Scripts)

Target endpoint is OpenAI-compatible:

POST /v1/chat/completions


You are testing steady-state behavior, not cold start.

Grafana/Prometheus are running to observe:

TTFT p95

Requests/sec by model

GPU utilization

GPU memory utilization

Common Environment Variables
BASE_URL=http://<router-host>:<port>
PATH_CHAT=/v1/chat/completions

1. Vegeta — Fixed RPS Load Test

Purpose

Validate request handling at a fixed request rate

Useful for quick throughput and latency sanity checks

Script

load-testing/scripts/vegeta_chat.sh


Dependencies

vegeta

Run

BASE_URL=http://<router-host>:<port> \
RATE=5 \
DURATION=120s \
./load-testing/scripts/vegeta_chat.sh


Observations

End-to-end request latency

Error rates under sustained RPS

Router and backend stability

2. k6 — Ramped Load / Soak Test

Purpose

Gradually increase concurrency

Observe system behavior during ramp-up, hold, and ramp-down

Script

load-testing/scripts/k6_chat.js


Dependencies

k6

Run

k6 run \
  -e BASE_URL=http://<router-host>:<port> \
  -e MODEL=<model-name> \
  load-testing/scripts/k6_chat.js


Observations

Latency growth as concurrency increases

Early signs of queueing

Stability during sustained load windows

3. Async Blast — Max Concurrency Test

Purpose

Push the system toward GPU saturation

Measure tail latency under high concurrency

Script

load-testing/scripts/async_blast.py


Dependencies

Python 3.9+

httpx

Install

pip install httpx


Run

BASE_URL=http://<router-host>:<port> \
CONCURRENCY=30 \
TOTAL_REQUESTS=600 \
python3 load-testing/scripts/async_blast.py


Observations

p50 / p95 / p99 request latency

Throughput vs concurrency

GPU utilization plateau behavior

4. Async Mix (70/30) — Multi-Model Traffic Test

Purpose

Validate routing rules with mixed model traffic

Observe per-model latency and GPU contention

Script

load-testing/scripts/async_mix_70_30.py


Dependencies

Python 3.9+

httpx

Run

BASE_URL=http://<router-host>:<port> \
MODEL_A=<model-A> \
MODEL_B=<model-B> \
WEIGHT_A=0.7 \
WEIGHT_B=0.3 \
CONCURRENCY=30 \
TOTAL_REQUESTS=900 \
python3 load-testing/scripts/async_mix_70_30.py


Observations

Requests/sec split per model (~70/30)

TTFT p95 per model

Shared GPU utilization and memory pressure

Routing correctness under load

Recommended Execution Order

Vegeta — quick validation

k6 — controlled ramp and soak

Async Blast — saturation limits

Async Mix — real-world multi-model behavior

Notes on Metrics

Scripts measure HTTP request latency, not true TTFT.

TTFT must be read from Grafana (backend metrics).

Use stream=false to keep timing consistent.

Expected Outcome

By running all four scripts, you should be able to:

Confirm routing correctness

Identify saturation points

Correlate latency with GPU pressure

Validate observability across layers
