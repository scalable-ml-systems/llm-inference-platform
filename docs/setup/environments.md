# Environments : dev/staging/production

ENV: dev/
Smallest GPU footprint, FSx disabled, observability enabled, autoscaling minimal.

ENV: staging/
Used for A/B router testing, shadow deployments, and load testing.
FSx enabled. GPU nodes medium sized.

ENV: prod/
Full GPU fleet, FSx enabled, autoscaling aggressive, cost‑management enabled.
