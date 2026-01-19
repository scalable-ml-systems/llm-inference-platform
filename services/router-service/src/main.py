from fastapi import FastAPI
from api.healthz import router as healthz_router
from api.readyz import router as readyz_router
from api.models import router as models_router
from api.chat_completions import router as chat_router
from observability.logging import configure_logging

app = FastAPI(title="router-service", version="0.1.0")

configure_logging()

app.include_router(healthz_router)
app.include_router(readyz_router)
app.include_router(models_router)
app.include_router(chat_router)

from observability.metrics import metrics_router
app.include_router(metrics_router)
