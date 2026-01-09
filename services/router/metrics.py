from prometheus_client import Counter, Histogram

# Track tokens processed and GPU time
tokens_processed_total = Counter(
    "tokens_processed_total",
    "Total number of tokens routed through the system"
)

gpu_seconds_total = Counter(
    "gpu_seconds_total",
    "Total GPU seconds consumed by routed requests"
)

# Track routing distribution
requests_shadow_total = Counter("requests_shadow_total", "Requests sent to shadow mode")
requests_canary_total = Counter("requests_canary_total", "Requests sent to canary mode")
requests_prod_total   = Counter("requests_prod_total", "Requests sent to production mode")

# Latency histogram
request_latency_seconds = Histogram(
    "request_latency_seconds",
    "Latency of routed requests in seconds"
)

def record_request(mode: str, tokens: int, gpu_seconds: float, latency: float):
    tokens_processed_total.inc(tokens)
    gpu_seconds_total.inc(gpu_seconds)
    if mode == "shadow":
        requests_shadow_total.inc()
    elif mode == "canary":
        requests_canary_total.inc()
    elif mode == "prod":
        requests_prod_total.inc()
    request_latency_seconds.observe(latency)
