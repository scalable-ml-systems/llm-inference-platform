import redis
import hashlib
import time

class ContextRegistry:
    """
    Redis-backed registry for session/prefix mapping.
    Ensures context affinity: same user/session routes to same vLLM pod.
    """

    def __init__(self, host="redis", port=6379, db=0, ttl_seconds=3600):
        self.client = redis.Redis(host=host, port=port, db=db, decode_responses=True)
        self.ttl = ttl_seconds

    def _hash_prefix(self, prefix: str) -> str:
        """Generate a stable hash key for a given prefix/context ID."""
        return hashlib.sha256(prefix.encode("utf-8")).hexdigest()

    def register_context(self, session_id: str, prefix: str, target_node: str) -> None:
        """
        Register a session/prefix mapping to a target vLLM node.
        """
        key = f"context:{session_id}:{self._hash_prefix(prefix)}"
        self.client.set(key, target_node, ex=self.ttl)

    def get_target_node(self, session_id: str, prefix: str) -> str | None:
        """
        Retrieve the target node for a given session/prefix.
        Returns None if no mapping exists.
        """
        key = f"context:{session_id}:{self._hash_prefix(prefix)}"
        return self.client.get(key)

    def refresh_context(self, session_id: str, prefix: str) -> None:
        """
        Refresh TTL for an existing context mapping.
        """
        key = f"context:{session_id}:{self._hash_prefix(prefix)}"
        if self.client.exists(key):
            self.client.expire(key, self.ttl)

    def delete_context(self, session_id: str, prefix: str) -> None:
        """
        Remove a context mapping (e.g., session ended).
        """
        key = f"context:{session_id}:{self._hash_prefix(prefix)}"
        self.client.delete(key)

    def stats(self) -> dict:
        """
        Return basic stats for observability:
        - total keys
        - memory usage
        - uptime
        """
        info = self.client.info()
        return {
            "keys": info.get("db0", {}).get("keys", 0),
            "used_memory_human": info.get("used_memory_human"),
            "uptime_in_seconds": info.get("uptime_in_seconds"),
        }


# Example usage
if __name__ == "__main__":
    registry = ContextRegistry()
    registry.register_context("session123", "Hello world", "vllm-node-1")
    node = registry.get_target_node("session123", "Hello world")
    print(f"Resolved node: {node}")
    print("Stats:", registry.stats())
