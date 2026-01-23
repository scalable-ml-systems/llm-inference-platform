# LLM Inference Platform (vLLM)
This is a production-style LLM inference system built on vLLM and designed to handle real load. The focus isn't on model performance—it's on understanding how latency, throughput, and GPU behavior actually work together in practice.
The system is organized into four layers, each doing one thing. That's it.

## Why this exists
LLM inference systems break in subtle ways. Latency spikes for no clear reason. GPUs look busy but nothing's happening. Routing decisions are a black box. One failure takes down everything else.
This platform is built to make those problems visible and predictable. Each layer enforces one invariant and contains its own failures.

## How it's structured


<img width="6090" height="5067" alt="vllm-architecture-final" src="https://github.com/user-attachments/assets/8af127cd-68f1-4f3e-a3ff-5edc83357119" />


Four layers, cleanly separated. Traffic admission doesn't know about routing. Routing doesn't touch GPU execution. Observability ties it all together.

## Tech Stack (by System Responsibility)

<table>
<tr>
<td width="50%" valign="top">

### **Compute**
- AWS EC2 (GPU + system nodes)
- NVIDIA GPUs
- vLLM (GPU‑backed inference)

### **Networking & Traffic Management**
- Envoy (Edge Gateway)
- Kubernetes Services & DNS
- Internal VPC networking (private subnets)

### **Storage & State**
- Redis (session affinity, routing state)
- GPU VRAM (model weights + KV cache)
- CPU RAM (prefill / spillover buffers)

### **Models**
- Mistral‑7B‑Instruct‑v0.2‑AWQ  
- Llama‑3.2‑8B‑Instruct‑AWQ

</td>
<td width="50%" valign="top">

### **Orchestration & Scheduling**
- Kubernetes
- Amazon EKS
- Helm (application deployment)

### **Control Plane & Routing**
- Custom Router Service (Python / FastAPI)
- Deterministic routing rules (YAML)
- Health‑aware forwarding & bounded retries

### **Observability & Telemetry**
- Prometheus (metrics collection)
- Grafana (dashboards)
- Loki (structured logs)
- Tempo (request tracing)
- DCGM (GPU telemetry)

### **Infrastructure as Code & Ops**
- Terraform (VPC, EKS, node groups, observability)
- Shell scripts (cost control, environment lifecycle)

</td>
</tr>
</table>


### Layer 1: Edge Gateway
This is the front door. It accepts traffic, validates it, and forwards good requests downstream.
What it does:

Checks that requests are well-formed
Rejects bad traffic immediately
Scales horizontally
Doesn't make routing decisions
Doesn't know anything about models or GPUs

Why: If you don't control traffic at the edge, every downstream component has to defend itself. That adds latency and couples failures across the system.

#### Architecture: 

<img width="8192" height="3594" alt="envoy-good-diagram" src="https://github.com/user-attachments/assets/e1d4b423-885f-4ae6-a167-838c2c2a35e3" />


### Layer 2: Router Service
This decides where each request should go.
What it does:

Looks at request metadata, backend health, and policy
Makes a routing decision and logs it
Handles retries with clear limits
Supports session affinity if needed
Everything is observable

Why: When routing logic lives inside gateways or inference code, it becomes impossible to test or understand. Pulling it into its own layer means you can change routing without touching GPU execution.

#### Architecture:

<img width="3558" height="735" alt="router" src="https://github.com/user-attachments/assets/4daed829-a224-4769-aa98-031548cd75a5" />


### Layer 3: Inference Backends
This runs the models on GPUs and returns results.
What it does:

Executes inference
Stays GPU-saturated
Warms up to avoid cold starts
Reports per-request latency and health
Doesn't know or care about routing

Why: GPU execution is expensive and fragile. Isolating it makes performance predictable and cost visible. You can experiment here without risking the control plane.

#### Architecture:

### Layer 4: Observability
This makes the system understandable.
What it does:

Tracks latency, throughput, and GPU utilization
Correlates signals across all layers
Produces structured logs
Alerts on things you can act on

Why: Without observability, you're guessing. You can't explain latency, plan capacity, or debug failures. This layer closes the loop between what the system does and why it does it.

What happens under load
Traffic hits the edge gateway, which validates and forwards it. The router decides where it should go and logs that decision. Inference backends execute on GPUs. Observability captures how everything interacts.
You can answer real questions:

Why did time-to-first-token increase?
Which backend handled this request and why?
Are the GPUs actually saturated or just stuck?
Where's the bottleneck—routing, execution, or capacity?


<img width="2048" height="1074" alt="End-to-End LLM Inference Under Sustained Load-1" src="https://github.com/user-attachments/assets/51967c76-ec95-4a8d-bfbd-a3e7fe1683b6" />



<img width="1299" height="1044" alt="dcgm-metrics" src="https://github.com/user-attachments/assets/814f2ac6-abfd-4510-98cb-3d00118ece57" />



<img width="1291" height="1030" alt="prefill-decode" src="https://github.com/user-attachments/assets/148b0788-9c71-45c9-8eb9-5cee4ae499a9" />



### Design principles

Each layer does one thing
Behavior is deterministic, not heuristic
Failures are bounded, not silent
Observe before optimizing
Configure, don't rewrite code


### What this is and isn't
This is a working system you can run and reason about. It's been tested under sustained load and organized for maintainability.
This is not a benchmark, a framework comparison, a demo, or a pile of scripts.

### Where things are

- services/edge-gateway/ — Layer 1
- services/router-service/ — Layer 2
- services/inference-backend/ — Layer 3
- services/observability/ — Layer 4
- infrastructure/ — Terraform and cluster setup
- load-testing/ — Load generation
- docs/ — Architecture details

Each layer has its own README explaining the internal design.

### Resources & References
- [vLLM Documentation](https://docs.vllm.ai/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)


### License
Apache 2.0 - See [LICENSE](LICENSE)

---
