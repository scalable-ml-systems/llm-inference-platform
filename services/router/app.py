"""
app.py
FastAPI Entrypoint for Intelligent Router Service
-------------------------------------------------
Roles:
- Receives inference requests
- Classifies prompt complexity (semantic_classifier)
- Enforces context affinity (context_registry)
- Forwards traffic to correct vLLM instance
- Records metrics (metrics)
"""

from fastapi import FastAPI, Request
import httpx
import hashlib

# === Import local modules ===
from semantic_classifier import classify_prompt
from context_registry import get_affinity, set_affinity
from metrics import record_request, record_latency

app = FastAPI()

# === Model Endpoints (Execution Plane) ===
MODEL_ENDPOINTS = {
    "qwen": "http://vllm-qwen:8000/v1/completions",
    "llama": "http://vllm-llama:8001/v1/completions"
}

# === Content-Aware Hashing Function ===
def content_hash(session_id: str, prefix: str) -> str:
    """
    Generate a stable hash based on session_id + prefix.
    Ensures repeated documents map to the same model instance.
    """
    key = f"{session_id}:{prefix}"
    h = int(hashlib.sha256(key.encode()).hexdigest(), 16)
    return "qwen" if h % 2 == 0 else "llama"

# === Router Endpoint ===
@app.post("/route")
async def route_request(request: Request):
    """
    Main routing endpoint:
    1. Extract session_id + prompt
    2. Classify prompt complexity
    3. Apply context-aware hashing + affinity
    4. Forward to correct vLLM instance
    5. Record metrics
    """
    body = await request.json()
    session_id = body.get("session_id", "anon")
    prompt = body.get("prompt", "")
    prefix = prompt[:50]  # first 50 chars for affinity

    # --- Step 1: Semantic Classification ---
    difficulty = classify_prompt(prompt)  # returns "easy" or "hard"

    # --- Step 2: Context Affinity Lookup ---
    target_model = get_affinity(session_id, prefix)
    if not target_model:
        # If no affinity mapping exists, decide based on classification + hash
        if difficulty == "easy":
            target_model = "qwen"
        else:
            target_model = content_hash(session_id, prefix)
        set_affinity(session_id, prefix, target_model)

    # --- Step 3: Forward Request ---
    async with httpx.AsyncClient() as client:
        resp = await client.post(MODEL_ENDPOINTS[target_model], json=body)
        result = resp.json()

    # --- Step 4: Record Metrics ---
    record_request(model=target_model, tokens=len(prompt.split()))
    record_latency(model=target_model, latency=resp.elapsed.total_seconds())

    return {
        "model": target_model,
        "difficulty": difficulty,
        "response": result
    }

# === Health Check Endpoint ===
@app.get("/health")
def health_check():
    return {"status": "ok", "router": "active"}

