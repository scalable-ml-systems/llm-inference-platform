import yaml
from typing import Any

def load_rules(path: str) -> dict[str, Any]:
    with open(path, "r") as f:
        return yaml.safe_load(f)

def _extract_prompt_text(body) -> str:
    # naive: concatenate user content
    parts = []
    for m in body.messages:
        if isinstance(m.content, str):
            parts.append(m.content)
        else:
            # if list of segments, join text fields when present
            for seg in m.content:
                if isinstance(seg, dict) and "text" in seg:
                    parts.append(str(seg["text"]))
    return "\n".join(parts)

def evaluate_rules(rules: dict[str, Any], body) -> tuple[str, str]:
    default_backend = rules.get("default_backend", "backend-a")
    for rule in rules.get("rules", []):
        when = rule.get("when", {})
        prompt = _extract_prompt_text(body)
        prompt_chars = len(prompt)
        max_tokens = body.max_tokens or 0

        if "max_tokens_gte" in when and max_tokens >= int(when["max_tokens_gte"]):
            return rule["route_to"], rule["name"]
        if "prompt_chars_gte" in when and prompt_chars >= int(when["prompt_chars_gte"]):
            return rule["route_to"], rule["name"]
        if "any_keywords" in when:
            kws = [k.lower() for k in when["any_keywords"]]
            p = prompt.lower()
            if any(k in p for k in kws):
                return rule["route_to"], rule["name"]

    return default_backend, "default"
