# ==============================================
# Python script : Parse Nvidia-Smi for sidecar
# ==============================================

import subprocess
from dataclasses import dataclass
from typing import Optional, Dict, Any


@dataclass
class GpuSnapshot:
    index: int = 0
    name: str = "unknown"
    util_pct: int = 0
    mem_used_mb: int = 0
    mem_total_mb: int = 0


def _run(cmd: list[str], timeout_s: float = 0.8) -> str:
    out = subprocess.check_output(cmd, timeout=timeout_s)
    return out.decode("utf-8", errors="replace").strip()


def read_gpu(index: int = 0) -> Optional[GpuSnapshot]:
    """
    Uses nvidia-smi to read a single GPU snapshot.
    Returns None if nvidia-smi is unavailable.
    """
    try:
        # Query without units for easier parsing.
        # Example output line:
        # "Tesla T4, 37, 7421, 15360"
        q = "name,utilization.gpu,memory.used,memory.total"
        raw = _run(
            ["nvidia-smi", f"--id={index}", f"--query-gpu={q}", "--format=csv,noheader,nounits"],
            timeout_s=0.8,
        )
        parts = [p.strip() for p in raw.split(",")]
        if len(parts) < 4:
            return None
        return GpuSnapshot(
            index=index,
            name=parts[0],
            util_pct=int(parts[1]),
            mem_used_mb=int(parts[2]),
            mem_total_mb=int(parts[3]),
        )
    except Exception:
        return None


def snapshot_to_dict(s: Optional[GpuSnapshot]) -> Dict[str, Any]:
    if s is None:
        return {"ok": False}
    return {
        "ok": True,
        "index": s.index,
        "name": s.name,
        "util_pct": s.util_pct,
        "mem_used_mb": s.mem_used_mb,
        "mem_total_mb": s.mem_total_mb,
    }
