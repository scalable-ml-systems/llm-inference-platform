import os
import time
import asyncio
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import httpx
from fastapi import FastAPI
from fastapi.responses import JSONResponse

from gpu import read_gpu, snapshot_to_dict


BACKEND_ID = os.getenv("BACKEND_ID", "backend")
MODEL_ID = os.getenv("MODEL_ID", "model")
VLLM_URL = os.getenv("VLLM_URL", "http://127.0.0.1:8000")
GPU_INDEX = int(os.getenv("GPU_INDEX", "0"))

# Tight timeouts: we never want status to hang.
VLLM_TIMEOUT_S = float(os.getenv("VLLM_TIMEOUT_S", "0.25"))
GPU_POLL_INTERVAL_S = float(os.getenv("GPU_POLL_INTERVAL_S", "1.0"))

app = FastAPI(title="Inference Backend Status Sidecar", version="0.1.0")

_latest_gpu: Optional[Dict[str, Any]] = None
_latest_gpu_ts: float = 0.0


async def poll_gpu_forever() -> None:
    global _latest_gpu, _latest_gpu_ts
    while True:
        snap = read_gpu(GPU_INDEX)
        _latest_gpu = snapshot_to_dict(snap)
        _latest_gpu_ts = time.time()
        await asyncio.sleep(GPU_POLL_INTERVAL_S)


async def vllm_ready_check() -> Dict[str, Any]:
    """
    Cheap readiness check: /v1/models should return quickly when vLLM is ready.
    """
    t0 = time.perf_counter()
    try:
        async with httpx.AsyncClient(timeout=VLLM_TIMEOUT_S) as client:
            r = await client.get(f"{VLLM_URL}/v1/models")
            ok = (r.status_code == 200)
    except Exception:
        ok = False
    latency_ms = (time.perf_counter() - t0) * 1000.0
    return {"ok": ok, "latency_ms": round(latency_ms, 2)}


@app.on_event("startup")
async def startup_event() -> None:
    asyncio.create_task(poll_gpu_forever())


@app.get("/internal/status")
async def internal_status() -> JSONResponse:
    vllm = await vllm_ready_check()

    # ready = vLLM ok AND GPU query ok (or GPU info missing but vLLM ok)
    gpu_ok = bool(_latest_gpu and _latest_gpu.get("ok", False))
    ready = bool(vllm["ok"] and (gpu_ok or _latest_gpu is not None))

    payload = {
        "ready": ready,
        "backend_id": BACKEND_ID,
        "model_id": MODEL_ID,
        "vllm": vllm,
        "gpu": _latest_gpu or {"ok": False},
        "gpu_age_ms": int((time.time() - _latest_gpu_ts) * 1000) if _latest_gpu_ts else None,
        # MVP load/latency placeholders (router can start polling now)
        "load": {"inflight": 0},
        "latency": {"p50_ms": None, "p95_ms": None, "p99_ms": None},
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    return JSONResponse(content=payload)
