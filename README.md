# LLM Inference Platform

This repository contains a production-oriented LLM inference platform designed to serve large language models with explicit guarantees around performance, cost, observability, and safety.

The platform focuses on runtime inference concerns:
- multi-model serving
- intelligent request routing
- GPU-efficient batching and concurrency
- AI-specific observability (latency, tokens/sec, GPU utilization)
- cost-per-token visibility
- evaluation and safety guardrails

This system intentionally does NOT cover model training or large-scale fine-tuning.
The goal is to model how LLMs are actually operated in production environments.

Initial deployment targets AWS EKS with GPU-backed nodes.
