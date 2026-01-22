#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
PATH_CHAT="${PATH_CHAT:-/v1/chat/completions}"
MODEL="${MODEL:-TheBloke/Mistral-7B-Instruct-v0.2-AWQ}"

# Load profile
RATE="${RATE:-2}"          # requests per second
DURATION="${DURATION:-60s}" # total time
TIMEOUT="${TIMEOUT:-120s}"

# If you need auth (optional)
AUTH_HEADER="${AUTH_HEADER:-}" # e.g. "Authorization: Bearer XXX"

PAYLOAD=$(cat <<JSON
{
  "model": "${MODEL}",
  "messages": [{"role":"user","content":"Write a 3 sentence summary of what TTFT measures in LLM inference."}],
  "temperature": 0.2,
  "max_tokens": 128,
  "stream": false
}
JSON
)

TARGETS=$(cat <<EOF
POST ${BASE_URL}${PATH_CHAT}
Content-Type: application/json
${AUTH_HEADER}

${PAYLOAD}
EOF
)

echo "==> Hitting: ${BASE_URL}${PATH_CHAT}  rate=${RATE}/s duration=${DURATION}"
echo "${TARGETS}" | vegeta attack -rate="${RATE}" -duration="${DURATION}" -timeout="${TIMEOUT}" \
  | tee results.bin \
  | vegeta report -type=text

echo "==> Histogram:"
vegeta report -type=hist[0,50ms,100ms,200ms,500ms,1s,2s,5s,10s,20s,40s,60s,90s,120s] results.bin
