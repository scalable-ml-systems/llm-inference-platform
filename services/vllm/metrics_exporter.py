from prometheus_client import Counter, Gauge

# KV cache metrics
kv_cache_hits_total = Counter("kv_cache_hits_total", "Total KV cache hits")
kv_cache_misses_total = Counter("kv_cache_misses_total", "Total KV cache misses")

# Batching efficiency
batch_size_avg = Gauge("batch_size_avg", "Average batch size observed")
batch_wait_time_avg = Gauge("batch_wait_time_avg", "Average wait time before batch execution")

# OOM events
oom_events_total = Counter("oom_events_total", "Total GPU OOM events")

# Cold start latency
model_load_time_seconds = Gauge("model_load_time_seconds", "Model load time in seconds")

def record_kv_cache(hit: bool):
    if hit:
        kv_cache_hits_total.inc()
    else:
        kv_cache_misses_total.inc()

def record_batch_metrics(size: int, wait_time: float):
    batch_size_avg.set(size)
    batch_wait_time_avg.set(wait_time)

def record_oom_event():
    oom_events_total.inc()

def record_model_load_time(seconds: float):
    model_load_time_seconds.set(seconds)
