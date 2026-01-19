from fastapi import APIRouter
from execution.health import get_backend_health_snapshot
from routing.decision import get_config

router = APIRouter()

@router.get("/v1/models")
async def list_models():
    cfg = get_config()
    snapshot = await get_backend_health_snapshot(cfg)
    return {
        "object": "list",
        "data": [
            {"id": "backend-a", "object": "model", "health": snapshot.get("backend-a")},
            {"id": "backend-b", "object": "model", "health": snapshot.get("backend-b")},
        ],
    }
