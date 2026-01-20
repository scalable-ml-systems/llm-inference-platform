import os
import yaml
from dataclasses import dataclass
from typing import Optional, Any
from functools import lru_cache
from config.loader import get_config


@dataclass
class Decision:
    backend: str
    reason: str
    fallback_backend: Optional[str] = None
    affinity_hit: bool = False

@lru_cache(maxsize=1)

def get_rules_path(cfg: dict[str, Any]) -> str:
    return cfg["routing_rules"]["path"]

from fastapi import Request
from contracts.openai import ChatCompletionsRequest
from affinity.keying import get_session_id
from affinity.registry import get_affinity_backend, set_affinity_backend
from execution.health import is_backend_healthy
from routing.rules import load_rules, evaluate_rules
from routing.decision import Decision, get_rules_path

async def decide_backend(cfg, req: Request, body: ChatCompletionsRequest) -> Decision:
    # 1) optional forced route header (debug)
    forced = req.headers.get("x-route-backend")
    if forced in ("backend-a", "backend-b"):
        fb = "backend-b" if forced == "backend-a" else "backend-a"
        return Decision(backend=forced, reason="forced_header", fallback_backend=fb, affinity_hit=False)

    # 2) affinity
    affinity_enabled = bool(cfg["affinity"]["enabled"] and cfg["redis"]["enabled"])
    session_id = None
    if affinity_enabled:
        session_id = get_session_id(req, cfg["affinity"]["header_session_id"])
        if session_id:
            chosen = await get_affinity_backend(cfg, session_id)
            if chosen and await is_backend_healthy(cfg, chosen):
                fb = "backend-b" if chosen == "backend-a" else "backend-a"
                return Decision(backend=chosen, reason="affinity_hit", fallback_backend=fb, affinity_hit=True)

    # 3) rules
    rules = load_rules(get_rules_path(cfg))
    backend, reason = evaluate_rules(rules, body)

    # if unhealthy, flip
    if not await is_backend_healthy(cfg, backend):
        backend = "backend-b" if backend == "backend-a" else "backend-a"
        reason = "rules_unhealthy_flip"

    fallback = "backend-b" if backend == "backend-a" else "backend-a"

    # write affinity on decision
    if affinity_enabled and session_id:
        await set_affinity_backend(cfg, session_id, backend)

    return Decision(backend=backend, reason=reason, fallback_backend=fallback, affinity_hit=False)
