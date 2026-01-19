# Router Service (Layer 2)

## What it does
- Exposes OpenAI-compatible `POST /v1/chat/completions`
- Routes to two upstreams:
  - backend-a (Mistral) default
  - backend-b (LLaMA) fallback/stronger
- Uses Redis for session affinity (`x-session-id -> backend`) with TTL
- Provides:
  - `/healthz`, `/readyz`, `/v1/models`, `/metrics`

## Quickstart (K8s)
```bash
kubectl apply -f services/router-service/k8s/00-namespace.yaml
kubectl apply -f services/router-service/k8s/10-redis.yaml
kubectl apply -f services/router-service/k8s/20-router-configmap.yaml
kubectl apply -f services/router-service/k8s/30-router-deploy.yaml
kubectl apply -f services/router-service/k8s/40-router-svc.yaml
