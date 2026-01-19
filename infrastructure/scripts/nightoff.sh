#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config (override via env)
# =========================
CLUSTER_NAME="${CLUSTER_NAME:-llm-inference-platform-dev}"
NG_SYSTEM="${NG_SYSTEM:-llm-inference-platform-dev-system}"
NG_GPU="${NG_GPU:-llm-inference-platform-dev-gpu}"

NAMESPACE="${NAMESPACE:-inference-backend}"
DEPLOY_A="${DEPLOY_A:-inference-backend-backend-a}"
DEPLOY_B="${DEPLOY_B:-inference-backend-backend-b}"

GPU_MAX_SIZE="${GPU_MAX_SIZE:-2}"
SYSTEM_MAX_SIZE="${SYSTEM_MAX_SIZE:-2}"

echo "=============================================="
echo " Night-Off: Scaling EVERYTHING to zero"
echo " Cluster:   ${CLUSTER_NAME}"
echo "=============================================="

# -------------------------
# Scale inference backends
# -------------------------
echo "==> Scaling inference deployments to 0"
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_A}" --replicas=0 || true
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_B}" --replicas=0 || true

# -------------------------
# Cleanup warmup jobs/pods
# -------------------------
echo "==> Cleaning up warmup jobs and pods (if any)"
kubectl -n "${NAMESPACE}" delete job -l app.kubernetes.io/role=warmup --ignore-not-found=true >/dev/null 2>&1 || true
kubectl -n "${NAMESPACE}" delete pod -l app.kubernetes.io/role=warmup --ignore-not-found=true >/dev/null 2>&1 || true

# -------------------------
# Scale GPU nodegroup to 0
# -------------------------
echo "==> Scaling GPU nodegroup to 0"
aws eks update-nodegroup-config \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_GPU}" \
  --scaling-config minSize=0,maxSize="${GPU_MAX_SIZE}",desiredSize=0 >/dev/null

# ----------------------------
# Scale system nodegroup to 0
# ----------------------------
echo "==> Scaling system nodegroup to 0"
aws eks update-nodegroup-config \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_SYSTEM}" \
  --scaling-config minSize=0,maxSize="${SYSTEM_MAX_SIZE}",desiredSize=0 >/dev/null

# -------------------------
# Status
# -------------------------
echo "==> Current nodegroup scaling configs:"
aws eks describe-nodegroup \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_GPU}" \
  --query 'nodegroup.scalingConfig' \
  --output json || true

aws eks describe-nodegroup \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_SYSTEM}" \
  --query 'nodegroup.scalingConfig' \
  --output json || true

echo "==> Current nodes:"
kubectl get nodes -o wide || true

# -------------------------
# Restore instructions
# -------------------------
echo ""
echo "=============================================="
echo " To restore cluster:"
echo "=============================================="
echo " aws eks update-nodegroup-config \\"
echo "   --cluster-name ${CLUSTER_NAME} \\"
echo "   --nodegroup-name ${NG_SYSTEM} \\"
echo "   --scaling-config minSize=1,maxSize=${SYSTEM_MAX_SIZE},desiredSize=1"
echo ""
echo " aws eks update-nodegroup-config \\"
echo "   --cluster-name ${CLUSTER_NAME} \\"
echo "   --nodegroup-name ${NG_GPU} \\"
echo "   --scaling-config minSize=1,maxSize=${GPU_MAX_SIZE},desiredSize=${GPU_MAX_SIZE}"
echo ""
echo " kubectl -n ${NAMESPACE} scale deploy ${DEPLOY_A} --replicas=1"
echo " kubectl -n ${NAMESPACE} scale deploy ${DEPLOY_B} --replicas=1"
echo "=============================================="
