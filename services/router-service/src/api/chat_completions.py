from fastapi import APIRouter, Request, Response
from contracts.openai import ChatCompletionsRequest
from routing.decision import decide_backend, get_config
from execution.upstream import forward_chat_completion
from observability.metrics import (
    inc_requests, inc_errors, observe_latency_ms, inc_affinity_hit, inc_affinity_miss, inc_fallback
)
import time
import uuid

router = APIRouter()

@router.post("/v1/chat/completions")
async def chat_completions(req: Request, body: ChatCompletionsRequest):
    cfg = get_config()

    request_id = req.headers.get("x-request-id") or str(uuid.uuid4())
    start = time.time()

    decision = await decide_backend(cfg, req, body)
    if decision.affinity_hit:
        inc_affinity_hit()
    else:
        inc_affinity_miss()

    # Primary attempt
    try:
        inc_requests(decision.backend, decision.reason)
        upstream_resp = await forward_chat_completion(cfg, decision.backend, req, body, request_id)
        latency_ms = int((time.time() - start) * 1000)
        observe_latency_ms(decision.backend, latency_ms)
        return Response(
            content=upstream_resp.content,
            status_code=upstream_resp.status_code,
            media_type=upstream_resp.headers.get("content-type", "application/json"),
            headers={"x-request-id": request_id},
        )
    except Exception as e:
        inc_errors(decision.backend, "exception")
        # Fallback attempt (at most 1, deterministic)
        if decision.fallback_backend:
            inc_fallback(decision.backend, decision.fallback_backend, "exception")
            try:
                inc_requests(decision.fallback_backend, "fallback")
                upstream_resp = await forward_chat_completion(cfg, decision.fallback_backend, req, body, request_id)
                latency_ms = int((time.time() - start) * 1000)
                observe_latency_ms(decision.fallback_backend, latency_ms)
                return Response(
                    content=upstream_resp.content,
                    status_code=upstream_resp.status_code,
                    media_type=upstream_resp.headers.get("content-type", "application/json"),
                    headers={"x-request-id": request_id},
                )
            except Exception:
                inc_errors(decision.fallback_backend, "exception")
        # Fail
        return {"error": {"message": "upstream failure", "type": "upstream_error", "request_id": request_id}}
