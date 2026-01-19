import httpx
from contracts.openai import ChatCompletionsRequest

def _url(cfg, backend: str) -> str:
    if backend == "backend-a":
        return cfg["upstreams"]["backend_a"]["base_url"]
    return cfg["upstreams"]["backend_b"]["base_url"]

async def forward_chat_completion(cfg, backend: str, req, body: ChatCompletionsRequest, request_id: str) -> httpx.Response:
    base = _url(cfg, backend)
    connect = cfg["timeouts"]["connect_ms"] / 1000
    total = cfg["timeouts"]["request_ms"] / 1000
    timeout = httpx.Timeout(timeout=total, connect=connect)

    headers = {}
    # propagate request-id
    headers["x-request-id"] = request_id
    # propagate session id if present (useful for backend logs)
    if "x-session-id" in req.headers:
        headers["x-session-id"] = req.headers["x-session-id"]

    async with httpx.AsyncClient(timeout=timeout) as client:
        return await client.post(f"{base}/v1/chat/completions", json=body.model_dump(), headers=headers)
