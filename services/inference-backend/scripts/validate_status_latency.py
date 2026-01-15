#!/usr/bin/env python3
import argparse
import sys
import time
import json
from urllib.parse import urljoin

import httpx


def percentile(sorted_vals, p: float) -> float:
    """
    Percentile with linear interpolation.
    p in [0,100].
    """
    if not sorted_vals:
        return float("nan")
    if p <= 0:
        return sorted_vals[0]
    if p >= 100:
        return sorted_vals[-1]

    k = (len(sorted_vals) - 1) * (p / 100.0)
    f = int(k)
    c = min(f + 1, len(sorted_vals) - 1)
    if f == c:
        return sorted_vals[f]
    d0 = sorted_vals[f] * (c - k)
    d1 = sorted_vals[c] * (k - f)
    return d0 + d1


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate /internal/status latency (in-cluster recommended).")
    ap.add_argument("--base-url", required=True, help="e.g. http://inference-backend-vllm-a:9000/")
    ap.add_argument("--path", default="/internal/status", help="status path (default: /internal/status)")
    ap.add_argument("--samples", type=int, default=200, help="number of requests (default: 200)")
    ap.add_argument("--warmup", type=int, default=20, help="warmup requests ignored in stats (default: 20)")
    ap.add_argument("--timeout-ms", type=float, default=200.0, help="per-request timeout in ms (default: 200)")
    ap.add_argument("--p95-ms", type=float, default=10.0, help="p95 threshold in ms (default: 10)")
    ap.add_argument("--p99-ms", type=float, default=20.0, help="p99 threshold in ms (default: 20)")
    ap.add_argument("--strict-ready", action="store_true", help="fail if response JSON has ready=false")
    ap.add_argument("--print-samples", action="store_true", help="print raw samples (ms)")
    args = ap.parse_args()

    url = urljoin(args.base_url.rstrip("/") + "/", args.path.lstrip("/"))
    timeout_s = args.timeout_ms / 1000.0

    lat_ms = []
    ready_false = 0
    failures = 0

    # Keep-alive client; http/1.1 is fine in-cluster
    with httpx.Client(timeout=timeout_s) as client:
        # Warmup
        for _ in range(max(args.warmup, 0)):
            try:
                client.get(url)
            except Exception:
                pass

        for i in range(args.samples):
            t0 = time.perf_counter_ns()
            try:
                r = client.get(url)
                t1 = time.perf_counter_ns()
                dt_ms = (t1 - t0) / 1e6

                if r.status_code != 200:
                    failures += 1
                    continue

                # Validate JSON shape minimally
                data = r.json()
                if args.strict_ready and (data.get("ready") is False):
                    ready_false += 1

                lat_ms.append(dt_ms)
            except Exception:
                failures += 1

    lat_ms_sorted = sorted(lat_ms)
    p50 = percentile(lat_ms_sorted, 50)
    p95 = percentile(lat_ms_sorted, 95)
    p99 = percentile(lat_ms_sorted, 99)
    mn = lat_ms_sorted[0] if lat_ms_sorted else float("nan")
    mx = lat_ms_sorted[-1] if lat_ms_sorted else float("nan")

    report = {
        "url": url,
        "samples_requested": args.samples,
        "samples_recorded": len(lat_ms_sorted),
        "failures": failures,
        "ready_false": ready_false,
        "min_ms": round(mn, 3),
        "p50_ms": round(p50, 3),
        "p95_ms": round(p95, 3),
        "p99_ms": round(p99, 3),
        "max_ms": round(mx, 3),
        "thresholds_ms": {"p95": args.p95_ms, "p99": args.p99_ms},
    }

    print(json.dumps(report, indent=2))

    if args.print_samples:
        print("\nRAW_SAMPLES_MS=" + ",".join(f"{x:.3f}" for x in lat_ms_sorted))

    # Gate conditions (your Definition of Done)
    if len(lat_ms_sorted) < max(20, args.samples // 2):
        print("\nFAIL: too few successful samples (network/Service issue).", file=sys.stderr)
        return 2

    if args.strict_ready and ready_false > 0:
        print(f"\nFAIL: ready=false observed {ready_false} times.", file=sys.stderr)
        return 3

    if p95 >= args.p95_ms:
        print(f"\nFAIL: p95 {p95:.3f}ms >= {args.p95_ms:.3f}ms", file=sys.stderr)
        return 4

    if p99 >= args.p99_ms:
        print(f"\nFAIL: p99 {p99:.3f}ms >= {args.p99_ms:.3f}ms", file=sys.stderr)
        return 5

    print("\nPASS ✅ /internal/status latency meets thresholds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
