from fastapi import APIRouter
from execution.health import check_any_backend_ready
from affinity.registry import redis_ping_if_enabled
from routing.decision import get_config

router = APIRouter()

@router.get("/readyz")
async def readyz():
    cfg = get_config()
    backends_ok = await check_any_backend_ready(cfg)
    redis_ok = await redis_ping_if_enabled(cfg)
    # Ready if at least one backend is up; Redis must be reachable if enabled
    return {"ready": bool(backends_ok and redis_ok)}
