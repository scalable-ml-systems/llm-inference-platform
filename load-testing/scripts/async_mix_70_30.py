#!/usr/bin/env python3
import asyncio
import json
import os
import random
import time
from dataclasses import dataclass

import httpx


@dataclass
class Config:
    base_url: str = os.getenv("BASE_URL", "http://localhost:8080")
    path_chat: str = os.getenv("PATH_CHAT", "/v1/chat/completions")

    # Models (must match router config)
    model_a: str = os.getenv("MODEL_A", "TheBloke/Mistral-7B-Instruct-v0.2-AWQ")
    model_b: str = os.getenv("MODEL_B", "Meta-Llama-3.1-8B-Instruct-AWQ")

    # Traffic split
    weight_a: float = float(os.getenv("WEIGHT_A", "0.7"))  # 70%
    weight_b: float = float(os.getenv("WEIGHT_B", "0.3"))  # 30%

    concurrency: int = int(os.getenv("CONCURRENCY", "30"))
    total_requests: int = int(os.getenv("TOTAL_REQUESTS", "600"))
    timeout_s: float = float(os.getenv("TIMEOUT_S", "120"))
    token: str = os.getenv("TOKEN", "")


def now_ms() -> float:
    return time.time() * 1000.0


def choose_model(cfg: Config) -> str:
    r = random.random()
    return cfg.model_a if r < cfg.weight_a else cfg.model_b


async def worker(
    wid: int,
    client: httpx.AsyncClient,
    cfg: Config,
    queue: asyncio.Queue,
    stats: dict,
):
    url = f"{cfg.base_url}{cfg.path_chat}"
    headers = {"Content-Type": "application/json"}
    if cfg.token:
        headers["Authorization"] = f"Bearer {cfg.token}"

    while True:
        item = await queue.get()
        if item is None:
            queue.task_done()
            return

        model = choose_model(cfg)
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": "Explain in one paragraph how GPU saturation affects TTFT."
                }
            ],
            "temperature": 0.2,
            "max_tokens": 128,
            "stream": False,
        }

        t0 = now_ms()
        ok = False
        try:
            r = await client.post(url, headers=headers, content=json.dumps(payload))
            ok = (r.status_code == 200)
        except Exception:
            ok = False
        t1 = now_ms()

        stats["count"] += 1
        stats["by_model"][model]["count"] += 1
        stats["lat_ms"].append(t1 - t0)

        if ok:
            stats["ok"] += 1
            stats["by_model"][model]["ok"] += 1
        else:
            stats["fail"] += 1
            stats["by_model"][model]["fail"] += 1

        queue.task_done()


def pct(values, p):
    if not values:
        return None
    values_sorted = sorted(values)
    k = int((len(values_sorted) - 1) * (p / 100.0))
    return values_sorted[k]


async def main():
    cfg = Config()

    limits = httpx.Limits(
        max_connections=cfg.concurrency * 2,
        max_keepalive_connections=cfg.concurrency * 2,
    )
    timeout = httpx.Timeout(cfg.timeout_s)

    queue: asyncio.Queue = asyncio.Queue()
    stats = {
        "count": 0,
        "ok": 0,
        "fail": 0,
        "lat_ms": [],
        "by_model": {
            cfg.model_a: {"count": 0, "ok": 0, "fail": 0},
            cfg.model_b: {"count": 0, "ok": 0, "fail": 0},
        },
    }

    for _ in range(cfg.total_requests):
        await queue.put(1)

    async with httpx.AsyncClient(limits=limits, timeout=timeout) as client:
        workers = [
            asyncio.create_task(worker(i, client, cfg, queue, stats))
            for i in range(cfg.concurrency)
        ]

        for _ in range(cfg.concurrency):
            await queue.put(None)

        t0 = time.time()
        await queue.join()
        t1 = time.time()

        for w in workers:
            await w

    elapsed = max(1e-9, (t1 - t0))
    rps = stats["count"] / elapsed

    print("\n=== MIXED LOAD SUMMARY ===")
    print(f"Target: {cfg.base_url}{cfg.path_chat}")
    print(f"Total Requests: {stats['count']}  OK: {stats['ok']}  Fail: {stats['fail']}")
    print(f"Throughput: {rps:.2f} req/s")
    print(
        f"Latency ms: p50={pct(stats['lat_ms'],50):.1f} "
        f"p95={pct(stats['lat_ms'],95):.1f} "
        f"p99={pct(stats['lat_ms'],99):.1f}"
    )

    print("\n--- Per Model ---")
    for m, s in stats["by_model"].items():
        print(f"{m}: requests={s['count']} ok={s['ok']} fail={s['fail']}")


if __name__ == "__main__":
    asyncio.run(main())
