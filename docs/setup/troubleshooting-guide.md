# Troubleshooting Guide — Common Issues and Fixes

This document captures **common failure modes encountered while building and operating the platform**, along with their root causes and resolutions.

---

## 1. Router is Running but No Traffic Reaches Backends

### Symptoms
- Router pod is `Running`
- Edge returns 200/504 intermittently
- Inference backend metrics show no traffic
- Router logs show upstream connection errors

### Root Cause
- Incorrect backend service DNS
- Backend service exists but has no ready endpoints
- Namespace mismatch between router and inference backend

### How to Diagnose
```bash
kubectl get svc -n inference-backend
kubectl get endpoints -n inference-backend

Check router logs:

kubectl logs -n router deploy/router-service

```
#### Fix :
 - Verify router-config.yaml upstream URLs match Kubernetes service DNS
 - Ensure inference backend pods are Ready
 - Confirm router and backend namespaces align with service DNS

2. Inference Pods Running but GPU Metrics Missing
 - vLLM pods are running
 - Inference works
 - Grafana shows no GPU utilization or memory metrics

#### Root Cause
 - DCGM exporter not running on GPU nodes
 - ServiceMonitor missing or mis-labeled
 - Prometheus not scraping DCGM targets

#### How to Diagnose
```
kubectl get pods -n observability | grep dcgm
kubectl get servicemonitors -n observability
```

#### Check Prometheus targets:

Open Prometheus UI → Targets → DCGM exporter

#### Fix:
- Ensure DCGM exporter is deployed as a DaemonSet
- Verify GPU nodes have DCGM pods scheduled
- Check ServiceMonitor labels match Prometheus selector

3. GPU Utilization is High but TTFT Spikes Dramatically
 - GPU utilization ~95–100%
 - GPU memory stable
 - TTFT p95 / p99 rising sharply
 - No increase in error rate

#### Root Cause
 - Queueing due to GPU saturation
 - Too many concurrent sequences
 - Long prompts increasing prefill cost

#### How to Diagnose
 - Check concurrent requests
 - Compare prompt lengths
 - Correlate TTFT with GPU memory and request rate

#### Fix
 - Reduce offered load
 - Adjust routing rules (prompt length / max tokens)
 - Add capacity (more GPUs or backends)
 - This is expected behavior under saturation — not a bug.

4. Router Fallback Not Triggering as Expected
 - Primary backend unhealthy
 - Requests fail instead of routing to fallback
 - No fallback-related logs or metrics

#### Root Cause
 - fallback_backend not loaded into runtime config
 - Retry/fallback logic not triggered due to status mismatch
 - Backend returning non-retryable status codes

#### How to Diagnose
```
kubectl logs -n router deploy/router-service | grep fallback

Inspect loaded config:

kubectl exec -n router deploy/router-service -- cat /etc/router/router-config.yaml
kubectl exec -n router deploy/router-service -- cat /etc/router/routing-rules.yaml

``` 

#### Fix:
 - Ensure config loader merges routing-rules.yaml
 - Confirm retry status codes match actual failures
 - Restart router after config changes

5. Inference Backend Starts but Immediately OOMs
  - Pod starts then crashes
  - Logs show CUDA OOM errors
  - Kubernetes restarts the pod repeatedly

#### Root Cause
 - Model too large for GPU
 - Insufficient GPU memory for configured concurrency
 - Warmup requests too large

#### How to Diagnose
```
kubectl logs -n inference-backend pod/<pod-name>


Check GPU memory:

kubectl exec -n inference-backend pod/<pod-name> -- nvidia-smi
```

##### Fix: 
 - Reduce model size or quantization
 - Reduce max concurrent sequences
 - Lower warmup request size

6. Warmup Job Never Completes
 - Warmup job stuck running
 - Backend never becomes Ready
 - No traffic reaches backend

#### Root Cause

 - Warmup prompt too large
 - Model download slow or failing
 - GPU not available on node
```
How to Diagnose
kubectl get jobs -n inference-backend
kubectl logs -n inference-backend job/<warmup-job-name>
```

### Fix
- Reduce warmup prompt size
- Verify GPU node availability
- Check image pull and model loading logs

7. Grafana Dashboards Show Data but Lines Are Missing
 - Panels render
 - Only one model line visible
 - Legends show more entries than plotted lines

#### Root Cause
 - Low traffic for some labels
 - Prometheus time window too short
 - Query aggregations collapsing series

#### How to Diagnose
 - Expand time window
 - Generate sustained load for all models
 - Inspect Prometheus query directly

#### Fix
 - Increase dashboard time range
 - Apply load consistently
 - Adjust PromQL aggregation labels if needed

8. Router Appears Healthy but Requests Time Out
 - Router health checks pass
 - Edge returns 504
 - Backends show low activity

#### Root Cause
 - Router request timeout too low
 - Backend taking longer due to prefill or queueing
 - Mismatch between router and backend timeout expectations

#### How to Diagnose
 - Compare router timeout config vs backend behavior
 - Inspect TTFT and queueing metrics

#### Fix
 - Increase router request timeout
 - Adjust routing rules for heavy requests
 - Reduce load or concurrency

9. Prometheus Scraping Stops After Redeploy
 - Metrics disappear after rollout
 - Targets show DOWN

#### Root Cause
 - ServiceMonitor labels changed
 - Namespace mismatch
 - Prometheus selector too restrictive

#### How to Diagnose
```
kubectl get servicemonitors -A
kubectl describe prometheus -n observability
```

#### Fix
 - Align ServiceMonitor labels with Prometheus selector
 - Redeploy ServiceMonitors after changes

10. System Feels “Slow” But Nothing Looks Broken
- No errors
- Latency higher than expected
- GPU utilization high

#### Root Cause
This is often normal saturation behavior:
 - GPUs fully utilized
 - Requests queue
 - TTFT rises gradually

#### How to Diagnose
 Correlate TTFT with GPU utilization and request rate
 - Check memory stability

#### Fix
This is a capacity question, not a bug:
 - Add GPUs
 - Reduce load
- Adjust routing policy

#### Final Note

Most issues fall into one of three categories:

 - Configuration mismatch
 - Capacity saturation
 - Observability wiring

The platform is designed so that none of these fail silently.
If behavior is unexpected, the answer should be visible in metrics or logs.

This document captures the most common cases encountered during real operation.

