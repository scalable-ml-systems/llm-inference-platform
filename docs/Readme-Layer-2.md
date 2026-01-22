# Layer 2 — Router Service

The Router Service is the **control plane** of the LLM inference platform.

It sits between the Edge Gateway and the GPU-backed inference backends and is responsible for **deterministically deciding where each request should execute**, based on request characteristics, backend health, and configured policy.

This layer does **not** run inference and does **not** manage GPUs directly.

---

## Responsibilities

The Router Service is responsible for:

- Accepting validated requests from the Edge Gateway
- Making deterministic routing decisions
- Forwarding requests to the selected inference backend
- Applying retries and fallback policies
- Preserving request affinity when enabled
- Exposing health, metrics, and structured logs

---

## What This Layer Does *Not* Do

- No model execution
- No GPU scheduling
- No batching or KV-cache management
- No traffic admission or authentication

Those concerns belong to other layers by design.

---

## Architectural Role

The router exists to enforce a single invariant:

> **Each request is routed to the most appropriate backend in a way that is explainable, observable, and safe under failure.**

Separating this logic prevents tight coupling between traffic management and GPU execution.

---

## Request Flow
-- add diagram--

#### Routing Model
 - Routing is policy-driven and deterministic.
 - Inputs to a Routing Decision
 - Request parameters (e.g. max_tokens)
 - Prompt characteristics (e.g. prompt length)
 - Keyword hints (simple lexical signals)
 - Backend health state
 - Optional session affinity
 - Outputs of a Routing Decision
 - A single routing decision containing:
 - Target backend

#### Reason / rule name
 - Affinity key (if applicable)

This decision is logged and counted for observability.

Configuration
router-config.yaml

Defines runtime behavior:
 - Upstream backends and base URLs
 - Timeouts and retry policy
 - Optional request affinity
 - Redis integration
 - Observability toggles
 - routing-rules.yaml

Defines routing policy:
- Default backend
- Fallback backend
- Ordered routing rules based on request features
- Routing behavior can be changed without modifying code.

Failure Handling
- The router is designed to fail safely:
- Bounded timeouts prevent request pile-up
- Limited retries avoid amplifying GPU load
- Fallback routing handles transient backend failures
- Circuit state (Redis-backed) prevents flapping backends from being hammered
- Failures are surfaced via metrics and logs, not hidden.
- Affinity (Optional)

When enabled:
- Requests with the same session ID are routed consistently
- Redis is used to store short-lived affinity mappings
- TTL-based expiration prevents long-lived coupling
- Affinity is isolated from routing logic and can be disabled without code changes.

Observability
- The router exposes:
- Request rate and routing distribution
- Decision latency
- Upstream latency and status codes
- Retry and fallback counts

All logs are structured (JSON) to support aggregation and tracing.
 - Operational Characteristics
 - Stateless by default
 - Horizontally scalable
 - Fast-path service (adds minimal latency)
 - Restart-safe (configuration loaded on startup)

Design Principles
- This router follows first-principles system design:
- Deterministic: same inputs produce the same decision
- Explainable: every decision has a reason
- Bounded: retries and timeouts are strictly limited
- Observable: behavior is measurable, not inferred
- Decoupled: routing logic is isolated from inference execution

Summary
- The Router Service is a real control-plane component, not a demo or shim.
- It exists to make inference behavior:
- predictable under load
- resilient to partial failure
- tunable without redeployment
- understandable through metrics
