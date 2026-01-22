# Layer 1 — Edge Gateway (Envoy + Kubernetes)

The Edge Gateway is the **entry point** into the vLLM inference platform.  
It safely and predictably admits traffic, enforces security and schema boundaries, and forwards sanitized requests to the Router Service (Layer 2).

This layer is **stateless**, **horizontally scalable**, and designed to **fail fast** for malformed or unauthorized traffic.


## 1. Responsibilities and non‑responsibilities

**Responsibilities**

- Terminate or pass through TLS
- Apply request shaping and limits
- Enforce protocol and schema boundaries
- Authenticate and authorize requests
- Forward sanitized requests to the Router Service
- Emit metrics, logs, and traces

**Intentionally does NOT do**

- Model selection  
- GPU awareness  
- Inference logic  
- Observability aggregation  


## 2. High‑level architectural flow with visuals

 -- mermaid main diagram --

## 3. Security model — how prompts are protected ?

[![](https://mermaid.ink/img/pako:eNplkk9r4zAQxb_KMKeWddP4TxxFh0LXWwJLe3FCFxZfhDVJBLbkleVs3ZDvXjnGhRCdJOY3b96TdMLSSEKOLf3rSJf0S4m9FXWhwa9GWKdK1QjtIAPRQlYp0u62uB6KL_poelgLR_9Ff8vkA5ObzpGFDdmjKqnQI5Y9PD2tuRcobd84kmAHN62Du-3r5n5k1iPzTlbtelDS-1Cuh7vff7aP9Q32onfGlgT5z-cMGlN5E9ReEbn3CZWqlYMf3mdfGSFB6bah0imjr9hNeaBawFFUSorras5hmO47fS4tqsn6SOQPo8Bz5w7Gqs9LtLYxuqVJwgPZdfSxPmXHAPdWSeQ7UbUUYE22FsMZT4NEgc57owK530raia5yBRb67Pv8tf81pkbubOc7ren2h-nQNT7J9Nrf4pa0JJuZTjvkYbS8aCA_4QfyiIUztkiT-YoliyRlqzjAHnnC0tmchel8lSZhksTxOcDPy9T5LF4uVnG0ZBFjLAmjRYAklTP2bfxzl693_gLYkMr5?type=png)](https://mermaid.live/edit#pako:eNplkk9r4zAQxb_KMKeWddP4TxxFh0LXWwJLe3FCFxZfhDVJBLbkleVs3ZDvXjnGhRCdJOY3b96TdMLSSEKOLf3rSJf0S4m9FXWhwa9GWKdK1QjtIAPRQlYp0u62uB6KL_poelgLR_9Ff8vkA5ObzpGFDdmjKqnQI5Y9PD2tuRcobd84kmAHN62Du-3r5n5k1iPzTlbtelDS-1Cuh7vff7aP9Q32onfGlgT5z-cMGlN5E9ReEbn3CZWqlYMf3mdfGSFB6bah0imjr9hNeaBawFFUSorras5hmO47fS4tqsn6SOQPo8Bz5w7Gqs9LtLYxuqVJwgPZdfSxPmXHAPdWSeQ7UbUUYE22FsMZT4NEgc57owK530raia5yBRb67Pv8tf81pkbubOc7ren2h-nQNT7J9Nrf4pa0JJuZTjvkYbS8aCA_4QfyiIUztkiT-YoliyRlqzjAHnnC0tmchel8lSZhksTxOcDPy9T5LF4uVnG0ZBFjLAmjRYAklTP2bfxzl693_gLYkMr5)

5.1 Client → Ingress
HTTPS/TLS: Prompts are encrypted in transit; only the endpoint with the private key can decrypt.

Protects against eavesdropping and tampering on the public network.

5.2 Ingress → Envoy
TLS passthrough: Ingress forwards encrypted bytes; Envoy is first to decrypt, or

TLS termination + re‑encryption: Ingress terminates TLS, validates, then re‑encrypts to Envoy.

5.3 Envoy (blast‑radius boundary)
Terminates TLS / mTLS.

Applies:

Authn (JWT, OAuth, mTLS)

Authz (RBAC)

Rate limiting and request shaping

Protocol and schema validation

Only valid, authenticated, schema‑correct prompts are forwarded.

5.4 Envoy → Router
mTLS inside the cluster:

Encryption in transit

Mutual authentication between Envoy and Router

Aligns with zero‑trust: never trust the network, always verify identity and intent.
