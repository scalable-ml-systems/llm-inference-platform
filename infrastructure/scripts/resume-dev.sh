#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-llm-inference-platform-dev}"
NG_SYSTEM="${NG_SYSTEM:-llm-inference-platform-dev-system}"
NG_GPU="${NG_GPU:-llm-inference-platform-dev-gpu}"

NAMESPACE="${NAMESPACE:-inference-backend}"
DEPLOY_A="${DEPLOY_A:-inference-backend-backend-a}"
DEPLOY_B="${DEPLOY_B:-inference-backend-backend-b}"

# Desired sizes
SYSTEM_DESIRED="${SYSTEM_DESIRED:-2}"
SYSTEM_MIN="${SYSTEM_MIN:-1}"
SYSTEM_MAX="${SYSTEM_MAX:-3}"

GPU_DESIRED="${GPU_DESIRED:-2}"
GPU_MIN="${GPU_MIN:-0}"
GPU_MAX="${GPU_MAX:-2}"

# EKS managed nodegroup constraint: maxSize must be >= 1
if [[ "${SYSTEM_MAX}" -lt 1 ]]; then SYSTEM_MAX=1; fi
if [[ "${GPU_MAX}" -lt 1 ]]; then GPU_MAX=1; fi

echo "==> AWS identity / region (sanity):"
aws sts get-caller-identity --output table
aws configure get region || true
echo "AWS_PROFILE=${AWS_PROFILE:-<unset>}"
echo

echo "==> Scaling system nodegroup up (min=${SYSTEM_MIN} max=${SYSTEM_MAX} desired=${SYSTEM_DESIRED})"
aws eks update-nodegroup-config \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_SYSTEM}" \
  --scaling-config "minSize=${SYSTEM_MIN},maxSize=${SYSTEM_MAX},desiredSize=${SYSTEM_DESIRED}"

echo "==> Scaling GPU nodegroup up (min=${GPU_MIN} max=${GPU_MAX} desired=${GPU_DESIRED})"
aws eks update-nodegroup-config \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_GPU}" \
  --scaling-config "minSize=${GPU_MIN},maxSize=${GPU_MAX},desiredSize=${GPU_DESIRED}"

echo "==> Waiting for nodegroups to become ACTIVE..."
for i in $(seq 1 60); do
  SYS_STATUS="$(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NG_SYSTEM}" --query 'nodegroup.status' --output text || echo "UNKNOWN")"
  GPU_STATUS="$(aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NG_GPU}" --query 'nodegroup.status' --output text || echo "UNKNOWN")"
  echo "   (${i}/60) system=${SYS_STATUS} gpu=${GPU_STATUS}"
  [[ "${SYS_STATUS}" == "ACTIVE" && "${GPU_STATUS}" == "ACTIVE" ]] && break
  sleep 10
done

echo "==> Waiting for Kubernetes nodes to register..."
for i in $(seq 1 120); do
  NODE_COUNT="$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  if [[ "${NODE_COUNT}" -ge 1 ]]; then
    echo "   Nodes registered: ${NODE_COUNT}"
    break
  fi
  echo "   (${i}/120) waiting for nodes..."
  sleep 10
done

echo "==> Waiting for GPU allocatable on ${GPU_DESIRED} node(s)..."
for i in $(seq 1 180); do
  GPU_NODES="$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}' 2>/dev/null | grep -c '^[1-9]' || true)"
  echo "   (${i}/180) GPU nodes ready: ${GPU_NODES}/${GPU_DESIRED}"
  if [[ "${GPU_NODES}" -ge "${GPU_DESIRED}" ]]; then
    break
  fi
  sleep 10
done

echo "==> Scaling inference deployments back to 1 (namespace=${NAMESPACE})"
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_A}" --replicas=1
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_B}" --replicas=1

echo "==> Done. Current status:"
kubectl -n "${NAMESPACE}" get pods -o wide || true
kubectl get nodes -o wide || true
