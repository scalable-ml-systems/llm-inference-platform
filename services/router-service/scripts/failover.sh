#!/usr/bin/env bash
set -euo pipefail

ROUTER_URL="${ROUTER_URL:-http://localhost:8080}"
SESSION="failover1"

echo "== baseline request =="
curl -sS "$ROUTER_URL/v1/models" | jq .

echo "== request (session pinned) =="
curl -sS "$ROUTER_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "x-session-id: $SESSION" \
  -d '{
    "messages": [{"role":"user","content":"say hello"}],
    "max_tokens": 32
  }' | jq .

echo ""
echo "Now kill one backend pod (backend-b OR backend-a) and re-run this script."
echo "Expected: router succeeds within 1 request (fallback) and /v1/models reflects health."
