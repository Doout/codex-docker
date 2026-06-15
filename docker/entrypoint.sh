#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${CODEX_HOME:-/root/.codex}" /workspace /root/.cache

exec "$@"
