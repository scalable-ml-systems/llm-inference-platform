#!/usr/bin/env python3
import asyncio
import json
import os
import time
from dataclasses import dataclass

import httpx


@dataclass
class Config:
    base_url: str = os.getenv("BASE_URL", "http://localhost:8080")
    path_chat: str = os.getenv("PATH_CHAT", "/v1/chat/completions")
    model: str = os.getenv("MODEL", "TheBloke/Mistral-7B-Instruct-v0.2-AWQ")
    concurrency: int = int(os.getenv("CONCURRENCY", "20"))
    total_requests: int = int(os.getenv("TOTAL_REQUESTS", "200"))
    timeout_s: float = float(os.getenv("TIMEOUT_S", "120"))
    token: str = os.getenv("TOKEN", "")


def now_ms() -> float:
    return time.time() * 1000.0


async def worker(name: str, client: httpx.AsyncClient, cfg: Config, queue: asyncio.Queue, stats: dict):
    url = f"{cfg.base_url}{cfg.path_chat}"
    headers = {"Content-Type": "application/json"}
    if cfg.token:
        headers["Authorization"] = f"Bearer {cfg.token}"

    while True:
        item = await queue.get()
        if item is None:
            queue.task_done()
            return

        payload = {
            "model": cfg.model,
            "messages": [{"role": "user", "content": "Give a concise explanation of GPU saturation effects on TTFT."}],
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
        if ok:
            stats["ok"] += 1
        else:
            stats["fail"] += 1
        stats["lat_ms"].append(t1 - t0)

        queue.task_done()


def pct(values, p):
    if not values:
        return None
    values_sorted = sorted(values)
    k = int((len(values_sorted) - 1) * (p / 100.0))
    return values_sorted[k]


async def main():
    cfg = Config()
    limits = httpx.Limits(max_connections=cfg.concurrency * 2, max_keepalive_connections=cfg.concurrency * 2)
    timeout = httpx.Timeout(cfg.timeout_s)

    queue: asyncio.Queue = asyncio.Queue()
    stats = {"count": 0, "ok": 0, "fail": 0, "lat_ms": []}

    for _ in range(cfg.total_requests):
        await queue.put(1)

    async with httpx.AsyncClient(limits=limits, timeout=timeout) as client:
        workers = [
            asyncio.create_task(worker(f"w{i}", client, cfg, queue, stats))
            for i in range(cfg.concurrency)
        ]

        # poison pills
        for _ in range(cfg.concurrency):
            await queue.put(None)

        t0 = time.time()
        await queue.join()
        t1 = time.time()

        for w in workers:
            await w

    lat = stats["lat_ms"]
    rps = stats["count"] / max(1e-9, (t1 - t0))
    print(f"Target: {cfg.base_url}{cfg.path_chat}")
    print(f"Requests: {stats['count']}  OK: {stats['ok']}  Fail: {stats['fail']}")
    print(f"Throughput: {rps:.2f} req/s")
    if lat:
        print(f"Latency ms: p50={pct(lat,50):.1f}  p95={pct(lat,95):.1f}  p99={pct(lat,99):.1f}  max={max(lat):.1f}")


if __name__ == "__main__":
    asyncio.run(main())
