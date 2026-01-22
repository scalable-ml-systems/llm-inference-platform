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

 [![](https://mermaid.ink/img/pako:eNplUtuK2zAQ_RUxTyl1LnbsXPSwUFzTBrawOKEPxS_CnnUEtuRK8rZJCPQX9hf7JR3b61228YOwOJeZM5oL5LpA4GDxZ4sqx89SlEbUmWL0NcI4mctGKMdiJiyLK4nK3YK7Dtyp0qC1t2jSoYl60ic2SYoS2Rfh8Jc4fbilph011a1Dw_ZonmSOmRpo8fTubsfZ18PhYc9M1651bNIYXTfuxWlHlISzw_2eTK11R6Pb8si0If7fP8-Uz5wah8VgMmiSV8287oRUuZZKOKnVO8Kn1h3VvDvP7CNLKQG7l7V09h3rwWinc10RZZ8fsRbsu6hk8Z9dyllfywolnTxTQy95Bko6HcxStI1WFtmEcjipSlZgLi1ZzWnQbTXGTqZvoyGnQTROhKD4bWojlinwoDSyAP4oKose1JRbdHe4dNIMHLWPGXD6LfBRULkMMnUlHb3UD61r4M60pOyHPF7ahsKOW_RqblAVaGLdKgfcD5e9B_AL_Aa-DWfBerX1o_VqEfnLIPDgBDwM17NwvdkEmyCKolW4vXpw7osuZtFy64eLYBMuVuTlbz3AQjptvg2r3G_09R-gy-hG?type=png)](https://mermaid.live/edit#pako:eNplUtuK2zAQ_RUxTyl1LnbsXPSwUFzTBrawOKEPxS_CnnUEtuRK8rZJCPQX9hf7JR3b61228YOwOJeZM5oL5LpA4GDxZ4sqx89SlEbUmWL0NcI4mctGKMdiJiyLK4nK3YK7Dtyp0qC1t2jSoYl60ic2SYoS2Rfh8Jc4fbilph011a1Dw_ZonmSOmRpo8fTubsfZ18PhYc9M1651bNIYXTfuxWlHlISzw_2eTK11R6Pb8si0If7fP8-Uz5wah8VgMmiSV8287oRUuZZKOKnVO8Kn1h3VvDvP7CNLKQG7l7V09h3rwWinc10RZZ8fsRbsu6hk8Z9dyllfywolnTxTQy95Bko6HcxStI1WFtmEcjipSlZgLi1ZzWnQbTXGTqZvoyGnQTROhKD4bWojlinwoDSyAP4oKose1JRbdHe4dNIMHLWPGXD6LfBRULkMMnUlHb3UD61r4M60pOyHPF7ahsKOW_RqblAVaGLdKgfcD5e9B_AL_Aa-DWfBerX1o_VqEfnLIPDgBDwM17NwvdkEmyCKolW4vXpw7osuZtFy64eLYBMuVuTlbz3AQjptvg2r3G_09R-gy-hG)

## 3. Full Zero‑Trust Multi‑Tenant Pipeline

[![](https://mermaid.ink/img/pako:eNplk9uK2zAURX_loKcpTVI7t3H0MNBmhtDSQvCYTgh5EfJxIsaWPLo0dUOgv9Bf7JdUiu3pQPwk-ayztbcuJ8JVjoQSgy8OJcd7wfaaVTsJ_quZtoKLmkkLGTADGcowXpYCpb1mVoF5kD9UAytm8ciaa2YbmC1q9ff3n0w7Y2GtSl9Ec82mgU2Vs6ivi-s3htZKldfEJhBPSj-H9racDe_uVhSyr4-gQ2K__FHYA9hWx6pn7MiVJ7cUvqMWRQMi94GFbeDmy1P2ofL971psO-wUWwFeMlEZeA_CqJJZoSRoV_bZVi37IAulOUL66ePSoy9OWRZ6DD9gxf6jKYXqrdOb1uXQcFVj3hlIPbim8Iglcgs9USMXheBwvKSH-nV_1h7fULgXpmaW--Cqs4p5B7fcZtjqfpYF6nAxwB9D7Wyv0trrUms0rrS9nzZkiqZW0mAfx__N-o3vK2RA9lrkhBasNDggFeqKhTk5hbYdsX5DcEeoH-ZYsLAI2cmz7_MHvFWqItRq5zu1cvtDP3F17vN0N_lV3KfIUS-Vk5bQ8WRy0SD0RH4SGsfTUTSeJ8lkMluMF9N4PCCNpxbjUZwsplEczW8TD83OA_Lrsmw0miez2SSeLm6jKJ5PkwHBXFilv7Xv6fKszv8Ae1IVeg?type=png)](https://mermaid.live/edit#pako:eNplk9uK2zAURX_loKcpTVI7t3H0MNBmhtDSQvCYTgh5EfJxIsaWPLo0dUOgv9Bf7JdUiu3pQPwk-ayztbcuJ8JVjoQSgy8OJcd7wfaaVTsJ_quZtoKLmkkLGTADGcowXpYCpb1mVoF5kD9UAytm8ciaa2YbmC1q9ff3n0w7Y2GtSl9Ec82mgU2Vs6ivi-s3htZKldfEJhBPSj-H9racDe_uVhSyr4-gQ2K__FHYA9hWx6pn7MiVJ7cUvqMWRQMi94GFbeDmy1P2ofL971psO-wUWwFeMlEZeA_CqJJZoSRoV_bZVi37IAulOUL66ePSoy9OWRZ6DD9gxf6jKYXqrdOb1uXQcFVj3hlIPbim8Iglcgs9USMXheBwvKSH-nV_1h7fULgXpmaW--Cqs4p5B7fcZtjqfpYF6nAxwB9D7Wyv0trrUms0rrS9nzZkiqZW0mAfx__N-o3vK2RA9lrkhBasNDggFeqKhTk5hbYdsX5DcEeoH-ZYsLAI2cmz7_MHvFWqItRq5zu1cvtDP3F17vN0N_lV3KfIUS-Vk5bQ8WRy0SD0RH4SGsfTUTSeJ8lkMluMF9N4PCCNpxbjUZwsplEczW8TD83OA_Lrsmw0miez2SSeLm6jKJ5PkwHBXFilv7Xv6fKszv8Ae1IVeg)

## 4. Security model — how prompts are protected

#### Client → Ingress
 - HTTPS/TLS: Prompts are encrypted in transit; only the endpoint with the private key can decrypt.
 - Protects against eavesdropping and tampering on the public network.

#### Ingress → Envoy
 - TLS passthrough: Ingress forwards encrypted bytes; Envoy is first to decrypt, or
 - TLS termination + re‑encryption: Ingress terminates TLS, validates, then re‑encrypts to Envoy.

#### Envoy (blast‑radius boundary)
- Terminates TLS / mTLS.
- Applies:
   - Authn (JWT, OAuth, mTLS)
   - Authz (RBAC)
   - Rate limiting and request shaping
   - Protocol and schema validation
   - Only valid, authenticated, schema‑correct prompts are forwarded.

#### Envoy → Router
- mTLS inside the cluster:
- Encryption in transit
- Mutual authentication between Envoy and Router
- Aligns with zero‑trust: never trust the network, always verify identity and intent.
