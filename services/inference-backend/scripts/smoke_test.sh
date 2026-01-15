#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-inference-backend}"
SVC_A="${SVC_A:-inference-backend-vllm-a}"   # change if your service name differs
SVC_B="${SVC_B:-inference-backend-vllm-b}"   # change if your service name differs

STATUS_PORT="${STATUS_PORT:-9000}"
VLLM_PORT="${VLLM_PORT:-8000}"

# In-cluster curl pod (no port-forwarding)
CURL_POD="curl-check-$(date +%s)"

cleanup() {
  kubectl -n "$NAMESPACE" delete pod "$CURL_POD" --ignore-not-found >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[smoke] creating temporary curl pod..."
kubectl -n "$NAMESPACE" run "$CURL_POD" \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  --command -- sleep 3600 >/dev/null

kubectl -n "$NAMESPACE" wait --for=condition=Ready pod/"$CURL_POD" --timeout=90s >/dev/null

check_status_fast() {
  local svc="$1"
  echo "[smoke] status check for ${svc}..."
  # Measure <10ms is hard in bash reliably; we enforce “very small” timeout and 20 samples.
  # Router-level requirement: fast + non-blocking. This ensures it never hangs.
  kubectl -n "$NAMESPACE" exec "$CURL_POD" -- sh -c \
    "for i in \$(seq 1 20); do curl -sS --max-time 0.2 http://${svc}:${STATUS_PORT}/internal/status >/dev/null || exit 1; done"
  echo "  OK"
}

check_vllm_models() {
  local svc="$1"
  echo "[smoke] vLLM /v1/models for ${svc}..."
  kubectl -n "$NAMESPACE" exec "$CURL_POD" -- sh -c \
    "curl -sS --max-time 1.0 http://${svc}:${VLLM_PORT}/v1/models | grep -q 'data' "
  echo "  OK"
}

check_status_payload() {
  local svc="$1"
  echo "[smoke] status payload fields for ${svc}..."
  kubectl -n "$NAMESPACE" exec "$CURL_POD" -- sh -c \
    "curl -sS --max-time 0.2 http://${svc}:${STATUS_PORT}/internal/status | grep -q '\"ready\"' && \
     curl -sS --max-time 0.2 http://${svc}:${STATUS_PORT}/internal/status | grep -q '\"gpu\"' && \
     curl -sS --max-time 0.2 http://${svc}:${STATUS_PORT}/internal/status | grep -q '\"vllm\"' "
  echo "  OK"
}

echo "[smoke] === Backend A ==="
check_status_fast "$SVC_A"
check_status_payload "$SVC_A"
check_vllm_models "$SVC_A"

echo "[smoke] === Backend B ==="
check_status_fast "$SVC_B"
check_status_payload "$SVC_B"
check_vllm_models "$SVC_B"

echo "[smoke] PASS "
