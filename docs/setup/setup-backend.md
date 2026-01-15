# Backend A
helm upgrade --install inference-a deployment/charts/inference-backend \
  -n inference-backend --create-namespace \
  -f deployment/charts/inference-backend/values-backend-a.yaml

# Backend B
helm upgrade --install inference-b deployment/charts/inference-backend \
  -n inference-backend \
  -f deployment/charts/inference-backend/values-backend-b.yaml
