# Layer 4 — Observability

**Goal:** Make routing decisions and GPU health visible.

## Components
- **Prometheus**: metrics + alert rules
- **Grafana**: dashboards
- **Loki** (optional): logs
- **Tempo** (optional): traces

## Metrics we expect
### Router
- `/metrics` exposed from router service
- Counters:
  - `router_http_requests_total{status,route,model,backend,tenant}`
- Histogram:
  - `router_request_duration_seconds_bucket{route,model,backend}`

### Backends (vLLM)
- `/metrics` exposed (native or sidecar)
- At minimum: `up` target health + request latency if available

### GPU
- DCGM exporter metrics (recommended):
  - `DCGM_FI_DEV_GPU_UTIL`
  - `DCGM_FI_DEV_FB_USED`, `DCGM_FI_DEV_FB_TOTAL`

## Folder map
- `grafana/dashboards/` — dashboard JSON
- `grafana/provisioning/` — datasource + dashboard provisioning
- `prometheus/rules/` — PrometheusRule alert groups
- `prometheus/scrape-configs/` — ServiceMonitors / scrape config stubs
- `loki/` — log stack (optional)
- `tempo/` — tracing stack (optional)

## Definition of Done
You can see:
- Routing decisions (volume, errors, route/model/backend labels)
- Backend health (targets up/down)
- GPU pressure (utilization + memory)
- Latency percentiles (p50/p95/p99)

And you get alerts for:
- Backend unhealthy
- GPU saturation/memory pressure
- Latency SLO violation
