#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-llm-inference-platform-dev}"
NG_SYSTEM="${NG_SYSTEM:-llm-inference-platform-dev-system}"
NG_GPU="${NG_GPU:-llm-inference-platform-dev-gpu}"

NAMESPACE="${NAMESPACE:-inference-backend}"
DEPLOY_A="${DEPLOY_A:-inference-backend-backend-a}"
DEPLOY_B="${DEPLOY_B:-inference-backend-backend-b}"

# System nodes overnight: keep 1 by default (set KEEP_SYSTEM_NODES=0 to turn off)
KEEP_SYSTEM_NODES="${KEEP_SYSTEM_NODES:-1}"

echo "==> Scaling inference deployments to 0 (namespace=${NAMESPACE})"
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_A}" --replicas=0 || true
kubectl -n "${NAMESPACE}" scale deploy "${DEPLOY_B}" --replicas=0 || true

echo "==> Scaling GPU nodegroup to 0 (cluster=${CLUSTER_NAME}, nodegroup=${NG_GPU})"
aws eks update-nodegroup-config \
  --cluster-name "${CLUSTER_NAME}" \
  --nodegroup-name "${NG_GPU}" \
  --scaling-config minSize=0,maxSize=1,desiredSize=0 >/dev/null

if [[ "${KEEP_SYSTEM_NODES}" == "1" ]]; then
  echo "==> Keeping system nodegroup at 1 (cluster=${CLUSTER_NAME}, nodegroup=${NG_SYSTEM})"
  aws eks update-nodegroup-config \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NG_SYSTEM}" \
    --scaling-config minSize=1,maxSize=2,desiredSize=1 >/dev/null
else
  echo "==> Scaling system nodegroup to 0 (cluster=${CLUSTER_NAME}, nodegroup=${NG_SYSTEM})"
  aws eks update-nodegroup-config \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NG_SYSTEM}" \
    --scaling-config minSize=0,maxSize=1,desiredSize=0 >/dev/null
fi

echo "==> Done. Current nodegroup scaling configs:"
aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NG_SYSTEM}" --query 'nodegroup.scalingConfig' --output json || true
aws eks describe-nodegroup --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NG_GPU}" --query 'nodegroup.scalingConfig' --output json || true

echo "==> (Optional) Check nodes:"
kubectl get nodes -o wide || true
