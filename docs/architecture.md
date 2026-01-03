## Architecture Overview

The platform follows a simple request lifecycle:

Client → Router → Inference Engine → Response

All requests emit metrics, logs, cost signals, and safety signals.
Routing decisions are explicit and observable.

The system is designed to operate under constrained GPU availability.
Scaling focuses on batching, concurrency, and intelligent routing rather than horizontal GPU expansion.
