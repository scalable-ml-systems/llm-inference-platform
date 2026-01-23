## Layer 3 — Inference Backend (GPU Execution)

This is where inference actually happens. GPUs run the models and return results.

This layer receives normalized requests from Layer‑2 (Router/Scheduler) and returns generated tokens back upstream. It is optimized for both low TTFT (Time To First Token) and low ITL (Inference Token Latency) through a combination of advanced scheduling, KV‑cache management, and parallelism strategies.

The job here is simple: execute requests predictably under load and expose enough signals so you can understand what's happening.

---

```

                +-----------------------------+
                |       Layer-2 Router        |
                |  (tenant routing, quotas)   |
                +--------------+--------------+
                               |
                               v
+---------------------------------------------------------------+
|                     Layer-3: vLLM Engine                      |
|---------------------------------------------------------------|
|  Scheduler  |  Continuous Batch Manager  |  KV Block Manager  |
|-------------+----------------------------+--------------------|
| - sequence  | - merges ready sequences   | - alloc/free KV    |
|   ordering  | - builds batched Q tensor  | - per-seq tables   |
| - fairness  | - dispatches GPU kernels   | - block recycling  |
+---------------------------------------------------------------+
|                     Model Execution Core                      |
|   - Prefill (TP)   - Decode (PP)   - Sampling   - Logits      |
+---------------------------------------------------------------+
                               |
                               v
                +-----------------------------+
                |       Layer-2 Router        |
                +-----------------------------+

```

## What we're optimizing for

Four things matter:

1. Stable latency when GPUs are saturated
2. Predictable memory behavior
3. Fast startup after deployment
4. Observable execution so you can debug when things go wrong

We care more about being able to reason about the system than hitting peak benchmark numbers.

---

## How GPU execution works

We're using a high-throughput inference engine with:
- Continuous batching (requests flow through, not wait for batch assembly)
- Paged KV cache (memory allocated efficiently)
- Concurrent sequence execution

GPUs are treated as shared, saturated resources. High utilization is good as long as latency stays bounded. We're not trying to keep GPUs idle.

---

## Cold start problem (and warmup)

Cold starts kill tail latency. When a backend starts, it needs to:
- Load model weights into GPU memory
- Initialize CUDA kernels
- Set up memory pools

If you start serving traffic immediately, the first requests are slow and unpredictable.

**Our fix: explicit warmup**

Before a backend accepts traffic:
- A Kubernetes Job runs at deployment time
- It sends representative inference requests through the system
- Traffic only gets routed once warmup completes

This means:
- TTFT is stable right after deployment
- No surprise latency spikes during rollouts
- Clear signal to upstream layers about when a backend is actually ready

Warmup isn't optional. It's a required step.

---

## Health checks

The backend exposes two signals:

**Readiness**: Model is loaded, warmed up, and ready to serve  
**Liveness**: Process is running and responsive

The router and Kubernetes use these to avoid sending traffic to backends that aren't ready or are failing.

This prevents cascading failures when backends restart or struggle under load.

---

## Making execution visible

Inference behavior under load is not obvious. You can't just look at GPU utilization and know what's happening.

We expose:
- Time to First Token (TTFT)
- End-to-end request latency
- Request concurrency (how many in flight)
- Tokens per second
- GPU utilization
- GPU memory usage

These metrics let you tell the difference between:
- Compute saturation (GPU is busy doing work)
- Memory pressure (running out of space)
- Queueing (requests waiting)
- Load imbalance (some backends slammed, others idle)

A lightweight sidecar collects these metrics without interfering with inference. If observability breaks, inference keeps running.

---

## What happens when you overload it

Overload is going to happen. We design for it.

When capacity is exceeded:
- GPU utilization stays high
- Queues grow
- TTFT increases before errors appear

This is intentional. The system degrades gracefully instead of falling over unpredictably.

The router sees these signals and makes decisions accordingly. Capacity planning happens upstream based on observable behavior, not guesses.

---

## What this layer doesn't do

To keep things clean:
- No routing decisions (that's Layer 2)
- No traffic shaping (that's Layer 1)
- No retries or fallbacks (handled upstream)
- No cross-backend coordination

This layer executes inference and reports what it's doing. That's it.

## vLLM - Internal Architechture (Full view what happens inside the system)

```
+----------------------------------------------------------------------------------+
|                                vLLM Inference Engine                             |
+----------------------------------------------------------------------------------+

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                                Request Layer                               │
   └────────────────────────────────────────────────────────────────────────────┘
                     | normalized requests from Router (Layer‑2)
                     v

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                                Scheduler                                   │
   │  - selects ready sequences (prefill or decode)                             │
   │  - enforces fairness, quotas, priorities                                   │
   │  - hands sequences to the batcher                                          │
   └────────────────────────────────────────────────────────────────────────────┘
                     |
                     v

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                         Continuous Batch Manager                            │
   │  - merges active sequences into a single batch                              │
   │  - builds batched Q tensor                                                  │
   │  - prepares per‑sequence metadata                                           │
   └────────────────────────────────────────────────────────────────────────────┘
                     |
                     v

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                           KV Cache Block Manager                            │
   │                                                                              │
   │  Global KV Block Pool (GPU Memory):                                          │
   │                                                                              │
   │   +--------+--------+--------+--------+--------+--------+--------+--------+  │
   │   |  B0    |  B1    |  B2    |  B3    |  B4    |  B5    |  B6    |  B7    |  │
   │   | free   | seq1   | seq3   | seq2   | seq1   | free   | seq4   | seq1   |  │
   │   +--------+--------+--------+--------+--------+--------+--------+--------+  │
   │                                                                              │
   │  Per‑Sequence Block Tables:                                                  │
   │                                                                              │
   │   Seq1 → [B1, B4, B7]                                                        │
   │   Seq2 → [B3, B8]                                                            │
   │   Seq3 → [B2, B9]                                                            │
   │   Seq4 → [B6]                                                                │
   │                                                                              │
   │  - alloc/free KV blocks                                                      │
   │  - maintain block tables                                                     │
   │  - ensure strict isolation                                                   │
   └────────────────────────────────────────────────────────────────────────────┘
                     |
                     v

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                           Model Execution Core                              │
   │                                                                              │
   │   Prefill Path (Tensor Parallelism):                                         │
   │     - large GEMMs                                                            │
   │     - full‑prompt processing                                                 │
   │     - optimized for TTFT                                                     │
   │                                                                              │
   │   Decode Path (Pipeline Parallelism):                                        │
   │     - 1‑token steps                                                          │
   │     - KV reuse                                                               │
   │     - optimized for ITL                                                      │
   │                                                                              │
   │   Sampling:                                                                  │
   │     - greedy, top‑k, top‑p, temperature                                      │
   │                                                                              │
   │   Logits → next token                                                        │
   └────────────────────────────────────────────────────────────────────────────┘
                     |
                     v

   ┌────────────────────────────────────────────────────────────────────────────┐
   │                               Output Layer                                 │
   │  - streams tokens back to Router (Layer‑2)                                  │
   │  - returns logprobs, metadata, completion status                            │
   └────────────────────────────────────────────────────────────────────────────┘

+----------------------------------------------------------------------------------+
|                         GPU Kernels (Attention + MLP)                            |
|  - batched Q                                                                     |
|  - per‑sequence KV fetched via block tables                                      |
|  - one forward pass for all active sequences                                     |
+----------------------------------------------------------------------------------+

```

## Summary

Layer 3 runs models on GPUs in a way that's stable and observable.

Warmup ensures backends are ready before they take traffic. Health checks prevent routing to unstable instances. Metrics expose what's actually happening under load.

Keeping this layer isolated from routing and admission logic means you can reason about latency, throughput, and GPU behavior without everything being coupled together.

When something goes wrong, you can see it. When you need more capacity, you know why.