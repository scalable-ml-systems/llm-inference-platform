#!/usr/bin/env bash
set -euo pipefail

ROUTER_URL="${ROUTER_URL:-http://localhost:8080}"

echo "== healthz =="
curl -sS "$ROUTER_URL/healthz" | jq .

echo "== readyz =="
curl -sS "$ROUTER_URL/readyz" | jq .

echo "== models =="
curl -sS "$ROUTER_URL/v1/models" | jq .

echo "== chat completions =="
curl -sS "$ROUTER_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "x-session-id: smoke1" \
  -d '{
    "model": "any",
    "messages": [{"role": "user", "content": "hello"}],
    "max_tokens": 32
  }' | jq .
