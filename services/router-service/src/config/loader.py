# /app/src/config/loader.py
import os
import yaml
from functools import lru_cache

@lru_cache(maxsize=1)
def get_config() -> dict:
    path = os.environ.get("ROUTER_CONFIG", "/etc/router/router-config.yaml")
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}
