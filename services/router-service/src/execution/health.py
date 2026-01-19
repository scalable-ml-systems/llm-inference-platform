import httpx
import time
from affinity.registry import circuit_is_open

_health_cache = {}  # backend -> (ok:bool, ts:float)

async def _probe(url: str, timeout_ms: int) -> bool:
    try:
        async with httpx.AsyncClient(timeout=timeout_ms / 1000) as client:
            r = await client.get(f"{url}/healthz")
            return r.status_code == 200
    except Exception:
        return False

async def is_backend_healthy(cfg, backend: str) -> bool:
    # cheap cache (2s)
    now = time.time()
    cached = _health_cache.get(backend)
    if cached and (now - cached[1]) < 2:
        return cached[0]

    if await circuit_is_open(cfg, backend):
        _health_cache[backend] = (False, now)
        return False

    url = cfg["upstreams"]["backend_a"]["base_url"] if backend == "backend-a" else cfg["upstreams"]["backend_b"]["base_url"]
    ok = await _probe(url, cfg["timeouts"]["connect_ms"])
    _health_cache[backend] = (ok, now)
    return ok

async def check_any_backend_ready(cfg) -> bool:
    a = await is_backend_healthy(cfg, "backend-a")
    b = await is_backend_healthy(cfg, "backend-b")
    return bool(a or b)

async def get_backend_health_snapshot(cfg):
    return {
        "backend-a": "healthy" if await is_backend_healthy(cfg, "backend-a") else "unhealthy",
        "backend-b": "healthy" if await is_backend_healthy(cfg, "backend-b") else "unhealthy",
    }
