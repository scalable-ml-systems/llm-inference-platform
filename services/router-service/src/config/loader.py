# Loads router-config.yaml and (optionally) routing-rules.yaml, returning a single merged config dict.
# services/router-service/src/config/loader.py
import os
import yaml
from functools import lru_cache


def _load_yaml(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}


@lru_cache(maxsize=1)
def get_config() -> dict:
    cfg_path = os.environ.get("ROUTER_CONFIG", "/etc/router/router-config.yaml")
    cfg = _load_yaml(cfg_path)

    # Load routing rules file if configured
    rules_path = None
    rr = cfg.get("routing_rules") or {}
    if isinstance(rr, dict):
        rules_path = rr.get("path")

    if rules_path:
        routing = _load_yaml(rules_path)

        # Keep full routing config in one place
        cfg["routing"] = routing

        # Promote commonly used fields for convenience/compat with execution layer
        # (so upstream.py can read cfg["fallback_backend"] safely)
        if "default_backend" in routing:
            cfg["default_backend"] = routing["default_backend"]
        if "fallback_backend" in routing:
            cfg["fallback_backend"] = routing["fallback_backend"]
        if "match_policy" in routing:
            cfg["match_policy"] = routing["match_policy"]
        if "rules" in routing:
            cfg["rules"] = routing["rules"]

    return cfg
