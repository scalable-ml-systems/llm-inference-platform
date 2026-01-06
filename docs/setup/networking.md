# vLLM Platform Architecture with Envoy Router

                           ┌──────────────────────────────┐
                           │          Clients              │
                           │  (Apps, APIs, Services)       │
                           └───────────────┬──────────────┘
                                           │
                                           ▼
                           ┌──────────────────────────────┐
                           │        Envoy Proxy           │
                           │  (Network Routing Layer)     │
                           │  - Load balancing            │
                           │  - mTLS / Auth               │
                           │  - Rate limiting             │
                           │  - Canary traffic            │
                           │  - Shadow traffic            │
                           └───────────────┬──────────────┘
                                           │
                                           ▼
                     ┌────────────────────────────────────────────┐
                     │        Application-Level Router            │
                     │   (Model-Aware Routing Intelligence)       │
                     │                                            │
                     │  - Model selection (7B vs 70B)             │
                     │  - Cost-aware routing                      │
                     │  - Safety routing (unsafe → safety model)  │
                     │  - Fallback logic                          │
                     │  - Prompt rewriting                        │
                     │  - Metadata logging                        │
                     └───────────────┬────────────────────────────┘
                                     │
             ┌───────────────────────┼───────────────────────────────┐
             │                       │                               │
             ▼                       ▼                               ▼
   ┌────────────────┐     ┌────────────────┐               ┌────────────────┐
   │   vLLM Model A  │     │   vLLM Model B  │               │   vLLM Model C  │
   │  (e.g., 7B)     │     │  (e.g., 13B)    │               │  (e.g., 70B)    │
   │  - KV cache     │     │  - KV cache     │               │  - KV cache     │
   │  - batching     │     │  - batching     │               │  - batching     │
   └────────────────┘     └────────────────┘               └────────────────┘
             │                       │                               │
             └───────────────┬──────┴───────────────┬───────────────┘
                             ▼                      ▼
                 ┌──────────────────┐     ┌──────────────────┐
                 │  Logging Layer   │     │  Metrics Layer    │
                 │  (Prompts,       │     │  (GPU, latency,   │
                 │   responses,     │     │   throughput)     │
                 └──────────┬───────┘     └──────────┬───────┘
                            │                        │
                            ▼                        ▼
                 ┌──────────────────┐     ┌──────────────────┐
                 │  Safety Engine   │     │ Evaluation Engine │
                 │  (PII, toxicity) │     │ (quality, drift)  │
                 └──────────────────┘     └──────────────────┘