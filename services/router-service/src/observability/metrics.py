from prometheus_client import Counter, Histogram, generate_latest
from fastapi import APIRouter, Response

requests_total = Counter("router_requests_total", "Requests", ["backend", "reason"])
errors_total = Counter("router_errors_total", "Errors", ["backend", "class"])
fallbacks_total = Counter("router_fallbacks_total", "Fallbacks", ["from_backend", "to_backend", "reason"])
affinity_hit_total = Counter("router_affinity_hit_total", "Affinity hits")
affinity_miss_total = Counter("router_affinity_miss_total", "Affinity misses")
latency_ms = Histogram("router_request_latency_ms", "Latency ms", ["backend"])

def inc_requests(backend: str, reason: str):
    requests_total.labels(backend=backend, reason=reason).inc()

def inc_errors(backend: str, err_class: str):
    errors_total.labels(backend=backend, class=err_class).inc()

def inc_fallback(frm: str, to: str, reason: str):
    fallbacks_total.labels(from_backend=frm, to_backend=to, reason=reason).inc()

def inc_affinity_hit():
    affinity_hit_total.inc()

def inc_affinity_miss():
    affinity_miss_total.inc()

def observe_latency_ms(backend: str, ms: int):
    latency_ms.labels(backend=backend).observe(ms)

metrics_router = APIRouter()

@metrics_router.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type="text/plain; version=0.0.4")
