#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
PATH_CHAT="${PATH_CHAT:-/v1/chat/completions}"
MODEL="${MODEL:-TheBloke/Mistral-7B-Instruct-v0.2-AWQ}"
STEP_SECONDS="${STEP_SECONDS:-60}"

# Concurrency steps (edit as needed)
STEPS=(${STEPS:-"5 10 20 30 40"})

post_one() {
  curl -sS "${BASE_URL}${PATH_CHAT}" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${MODEL}\",
      \"messages\": [{\"role\":\"user\",\"content\":\"One sentence: what does TTFT measure?\"}],
      \"temperature\": 0.2,
      \"max_tokens\": 64,
      \"stream\": false
    }" > /dev/null
}

echo "==> Step ramp against ${BASE_URL}${PATH_CHAT}"
for c in "${STEPS[@]}"; do
  echo "==> Concurrency=${c} for ${STEP_SECONDS}s"
  end=$((SECONDS + STEP_SECONDS))
  while [ $SECONDS -lt $end ]; do
    for _ in $(seq 1 "$c"); do
      post_one &
    done
    wait
  done
done

echo "==> Done."
