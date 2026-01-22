# services/router-service/src/execution/upstream.py

import httpx
from typing import Optional

from contracts.openai import ChatCompletionsRequest


class UpstreamError(Exception):
    """Base class for upstream execution failures."""


class UpstreamTimeout(UpstreamError):
    def __init__(self, backend: str, msg: str = "upstream timeout"):
        super().__init__(f"{msg}: {backend}")
        self.backend = backend


class UpstreamConnectionError(UpstreamError):
    def __init__(self, backend: str, msg: str = "upstream connection error"):
        super().__init__(f"{msg}: {backend}")
        self.backend = backend


def _url(cfg, backend: str) -> str:
    # Router rules use backend names "backend-a"/"backend-b"
    if backend == "backend-a":
        return cfg["upstreams"]["backend_a"]["base_url"]
    return cfg["upstreams"]["backend_b"]["base_url"]


def _retry_policy(cfg) -> tuple[int, set[int]]:
    """
    retries.max_attempts is treated as 'number of retries after the first attempt'.
    Total attempts per backend = 1 + max_attempts.
    """
    r = cfg.get("retries", {}) or {}
    max_retries = int(r.get("max_attempts", 0))
    retry_on = set(r.get("retry_on_status", []) or [])
    return max_retries, retry_on


def _fallback_backend(cfg) -> Optional[str]:
    """
    Optional: allow fallback policy to be injected into cfg by the config loader.
    If not present, no fallback happens here.
    """
    fb = cfg.get("fallback_backend")
    return fb if isinstance(fb, str) and fb.strip() else None


async def _post_once(
    client: httpx.AsyncClient,
    url: str,
    headers: dict,
    body: ChatCompletionsRequest,
    backend: str,
) -> httpx.Response:
    try:
        return await client.post(url, json=body.model_dump(), headers=headers)
    except httpx.TimeoutException as e:
        raise UpstreamTimeout(backend) from e
    except httpx.RequestError as e:
        raise UpstreamConnectionError(backend) from e


async def forward_chat_completion(
    cfg,
    backend: str,
    req,
    body: ChatCompletionsRequest,
    request_id: str,
) -> httpx.Response:
    """
    Forwards an OpenAI-compatible chat completion request to the chosen backend.

    Behavior:
    - Bounded timeouts (connect + total) from cfg
    - Retry-on-status + max retries from cfg.retries
    - Optional single fallback to cfg.fallback_backend if present
    - Propagates x-request-id and x-session-id headers
    """
    base = _url(cfg, backend)
    connect = cfg["timeouts"]["connect_ms"] / 1000
    total = cfg["timeouts"]["request_ms"] / 1000
    timeout = httpx.Timeout(timeout=total, connect=connect)

    # Propagate request context
    headers = {"x-request-id": request_id}
    if "x-session-id" in req.headers:
        headers["x-session-id"] = req.headers["x-session-id"]

    max_retries, retry_on = _retry_policy(cfg)
    fallback = _fallback_backend(cfg)

    async with httpx.AsyncClient(timeout=timeout) as client:
        # 1) Try primary backend with bounded retries
        primary_url = f"{base}/v1/chat/completions"
        last_exc: Optional[Exception] = None

        for attempt in range(0, 1 + max_retries):
            try:
                resp = await _post_once(client, primary_url, headers, body, backend)
            except UpstreamError as e:
                last_exc = e
                # Retry only within attempt budget
                if attempt < max_retries:
                    continue
                break

            # If response status is retryable, retry within budget
            if resp.status_code in retry_on and attempt < max_retries:
                continue

            return resp  # success (or non-retryable status)

        # 2) Optional fallback (single attempt, no extra complexity)
        if fallback and fallback != backend:
            fb_base = _url(cfg, fallback)
            fb_url = f"{fb_base}/v1/chat/completions"
            return await _post_once(client, fb_url, headers, body, fallback)

        # 3) No fallback: re-raise last upstream exception if we have one
        if last_exc is not None:
            raise last_exc

        # If we got here, it means we only saw retryable HTTP statuses and exhausted retries.
        # Return the last response-like failure by making one final request (rare edge case),
        # or raise a generic error. We'll raise to keep failure explicit.
        raise UpstreamError(f"exhausted retries for {backend}")
