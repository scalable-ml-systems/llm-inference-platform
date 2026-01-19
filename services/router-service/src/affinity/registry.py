from redis.asyncio import Redis
from routing.decision import get_config
from typing import Optional

_redis: Optional[Redis] = None

async def _client(cfg) -> Optional[Redis]:
    global _redis
    if not cfg["redis"]["enabled"]:
        return None
    if _redis is None:
        _redis = Redis.from_url(cfg["redis"]["url"], decode_responses=True)
    return _redis

async def redis_ping_if_enabled(cfg) -> bool:
    if not cfg["redis"]["enabled"]:
        return True
    r = await _client(cfg)
    try:
        return bool(await r.ping())
    except Exception:
        return False

def _affinity_key(cfg, session_id: str) -> str:
    return f"{cfg['redis']['key_prefix_affinity']}{session_id}"

def _circuit_key(cfg, backend: str) -> str:
    return f"{cfg['redis']['key_prefix_circuit']}{backend}"

async def get_affinity_backend(cfg, session_id: str) -> Optional[str]:
    r = await _client(cfg)
    if r is None:
        return None
    return await r.get(_affinity_key(cfg, session_id))

async def set_affinity_backend(cfg, session_id: str, backend: str) -> None:
    r = await _client(cfg)
    if r is None:
        return
    ttl = int(cfg["affinity"]["ttl_seconds"])
    await r.set(_affinity_key(cfg, session_id), backend, ex=ttl)

async def circuit_is_open(cfg, backend: str) -> bool:
    r = await _client(cfg)
    if r is None:
        return False
    v = await r.get(_circuit_key(cfg, backend))
    return v == "open"

async def open_circuit(cfg, backend: str) -> None:
    r = await _client(cfg)
    if r is None:
        return
    ttl = int(cfg["redis"]["circuit_open_ttl_seconds"])
    await r.set(_circuit_key(cfg, backend), "open", ex=ttl)
